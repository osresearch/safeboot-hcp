#!/bin/bash

. /hcp/enrollsvc/common.sh

expect_root

# Detect in-place upgrade of the next-oldest version (which is the absence of
# any version tag!). The upgrade is done by enrollsvc-mgmt, so we just spin
# waiting for it to happen.
while [[ ! -f $HCP_ENROLLSVC_STATE_PREFIX/version ]]; do
	echo "Warning: stalling 'enrollsvc-repl' until in-place upgrade!" >&2
	sleep 30
done

# Validate that version is an exact match (obviously we need the same major,
# but right now we expect+tolerate nothing other than the same minor too).
(state_version=`cat $HCP_ENROLLSVC_STATE_PREFIX/version` &&
	[[ $state_version == $HCP_VER ]]) ||
(echo "Error: expected version $HCP_VER, but got '$state_version' instead" &&
	exit 1) || exit 1

echo "Running 'enrollsvc-repl' service (git-daemon)"

GITDAEMON=${HCP_RUN_ENROLL_GITDAEMON:=/usr/lib/git-core/git-daemon}
GITDAEMON_FLAGS=${HCP_RUN_ENROLL_GITDAEMON_FLAGS:=--reuseaddr --verbose --listen=0.0.0.0 --port=9418}

TO_RUN="$GITDAEMON \
	--base-path=$HCP_ENROLLSVC_STATE_PREFIX \
	$GITDAEMON_FLAGS \
	$REPO_PATH"

echo "Running (as $DB_USER): $TO_RUN"
drop_privs_db $TO_RUN
