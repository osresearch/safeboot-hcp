#!/bin/bash

. /hcp/enrollsvc/common.sh

expect_db_user

# This construct simplifies quite a few error cases. It also sidesteps some
# permissions issues with using tee (inside sudo, inside su, inside docker)
function my_tee {
	echo -n "$1"
	echo -n "$1" >&2
	return $2
}

echo "Starting $0" >&2
echo "  - Param1=$1 (path to ek.pub/ek.pem)" >&2
echo "  - Param2=$2 (hostname)" >&2
echo "  - Param3=$3 (profile)" >&2
echo "  - Param4=$4 (path to paramfile)" >&2

# args must be non-empty
if [[ -z $1 || -z $2 ]]; then
	echo "Error, missing at least one argument" >&2
	exit 1
fi

check_hostname "$2"
HNREV=`echo "$2" | rev`

cd /safeboot

# Invoke attest-enroll, which creates a directory full of goodies for the host.
# attest-enroll uses CHECKOUT and COMMIT hooks to determine the directory and
# post-process it, respectively. What we do is;
# - pick an output directory (mktemp -d -u), and store it in EPHEMERAL_ENROLL
# - call attest-enroll with our hooks
#   - our CHECKOUT hook reads $EPHEMERAL_ENROLL and returns it to attest-enroll
#     (via stdout),
#   - our COMMIT hook does nothing (flexibility later)
# - add all the goodies to git
#   - use the ek.pub goodie (which won't necessarily match $1, if the latter is
#     in PEM format!) to determine the EKPUBHASH
# - delete the temp output directory.

export EPHEMERAL_ENROLL=`mktemp -d -u`

# For now, we pass the 'profile' ($3) and 'paramfile' ($4) arguments as
# exported environment variables. Better would be to add the following to the
# attest-enroll command line;
#     -V PROFILE="$3"
#     -V PARAMFILE="$4"
# But this requires that sbin/attest-enroll support these configuration
# variables. I.e.  by adding these declarations to the attest-enroll script;
#     vars[PROFILE]=scalar
#     vars[PARAMFILE]=scalar
export ENROLL_PROFILE=$3
export ENROLL_PARAMFILE=$4

./sbin/attest-enroll -C /safeboot/enroll.conf \
		-V CHECKOUT=/hcp/enrollsvc/cb_checkout.sh \
		-V COMMIT=/hcp/enrollsvc/cb_commit.sh \
		-I $1 $2 >&2 ||
	my_tee "Error, 'attest-enroll' failed" 1 ||
	exit 1

[[ -f "$EPHEMERAL_ENROLL/ek.pub" ]] ||
	my_tee "Error, ek.pub file not where it is expected" 1 ||
	exit 1

EKPUBHASH="$(sha256sum "$EPHEMERAL_ENROLL/ek.pub" | cut -f1 -d' ')"
HALFHASH=`echo $EKPUBHASH | cut -c 1-16`

cd $REPO_PATH

# The following code is the critical section, so surround it with lock/unlock.
# Also, make sure nothing (sane) causes an exit/abort without us making it to
# the unlock. Any error should set 'itfailed', print any desired, user-visible
# explanation to stdout, and no subsequent steps should run unless 'itfailed'
# isn't set. NB: do not leak anything sensitive to stdout!! In error cases,
# stdout ends up in the user's JSON response.
repo_cmd_lock ||
	my_tee "Error, failed to lock repo" 1 ||
	exit 1
unset itfailed

# Ensure an "exclusive" enrollment, i.e. if the directory already exists, the
# TPM is already enrolled, and we're not (yet) supporting enrollment
# modifications!
# NB: the TPM-already-enrolled case returns 2, not 1, in order for the user to
# be able to distinguish this. (In many environments, redundant/surplus events
# are an expected side-effect of reliability mechanisms, and so it's useful to
# be able to treat the "enrollment failed only because it was already enrolled"
# case as a soft/non-error.)
function prep_enrollment {
	[[ -n "$itfailed" ]] && return
	ply_path_add "$EKPUBHASH"
	[[ -d "$FPATH" ]] &&
		my_tee "Error, TPM is already enrolled" 0 &&
		itfailed=2 && return
	mkdir -p "$FPATH" && return
	my_tee "Error, failed to mkdir $FPATH" 0 &&
		itfailed=1
}
prep_enrollment

# Combine the existing hn2ek with the new entry, sort the result, and put in
# hn2ek.tmp (it will replace the existing one iff other steps succeed).
function update_hn2ek {
	[[ -n "$itfailed" ]] && return
	echo "$HNREV `basename $FPATH`" | cat - $HN2EK_PATH | sort > $HN2EK_PATH.tmp && return
	my_tee "Error, hn2ek manipulation failed" 0
	itfailed=1
}
update_hn2ek

# Add the enrolled attributes to the DB, update hn2ek, and git add+commit.
function update_git {
	[[ -n "$itfailed" ]] && return
	(echo "$EKPUBHASH" > "$FPATH/ekpubhash" &&
		cp -a $EPHEMERAL_ENROLL/* "$FPATH/" &&
		mv $HN2EK_PATH.tmp $HN2EK_PATH &&
		git add . &&
		git commit -m "map $HALFHASH to $2") >&2 && return
	my_tee "Error, failed to add enrollment to git repo" 0
	itfailed=1
}
update_git

# TODO:
# 1. This exception/error/rollback path (necessarily before releasing the lock)
#    needs an alert valve of some kind. It's implemented to maximise
#    reliability/recovery, by trying to force the clone back to its previous
#    state, but we really ought to tell someone what we know before we
#    deliberately try to erase all trace. E.g. if "git reset" is adding loads
#    of erroneously-deleted files back to the checkout, or if "git clean" is
#    removing loads of erroneously-generated junk out of the checkout, that
#    information might indicate what's going wrong.
# 2. More urgently: if our failure-handling code fails to rollback correctly,
#    we _REALLY_ have to escalate! For now, we simply leave the repo locked,
#    which is not the most effective nor appreciated escalation method.
function recover_git {
	[[ -z "$itfailed" ]] && return
	(echo "Failure, attempting recovery" &&
		echo "running 'git reset --hard'" && git reset --hard &&
		echo "running 'git clean -f -d -x'" && git clean -f -d -x) >&2 && return
	my_tee "\nFatal, error-recovery failed! LOCKING ENROLLSVC!" 0
	rollbackfailed=1
}
recover_git

# If recovery failed, refuse to unlock the repo, forcing an intervention and
# blocking further modifications.
[[ -z "$rollbackfailed" ]] && repo_cmd_unlock

# If it failed, fail
[[ -n "$itfailed" ]] && exit $itfailed

rm -rf $EPHEMERAL_ENROLL

jq -Rn --arg hostname "$2" --arg ekpubhash "$HALFHASH" \
	'{returncode: 0, hostname: $hostname, ekpubhash: $ekpubhash}'

/bin/true
