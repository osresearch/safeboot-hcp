# This is an include-only file. So no shebang header and no execute perms.
# It is common to the git server and to attestation updaters that pull from the
# git server. EK_PATH must point to the 'ekpubhash' directory (in the
# "enrolldb.git" repo/clone).

if [[ -z "$EK_PATH" || ! -d "$EK_PATH" ]]; then
	if [[ -z "$DB_IN_SETUP" ]]; then
		echo "Error, EK_PATH must point to the ekpubhash lookup tree" >&2
		exit 1
	fi
fi

# ekpubhash must consist only of lower-case hex, and be at least 16 characters
# long (8 bytes)
function check_ekpubhash {
	(echo "$1" | egrep -e "^[0-9a-f]{16,}$" > /dev/null 2>&1) ||
		(echo "Error, malformed ekpubhash" >&2 && exit 1) || exit 1
}

# the prefix version can be any length (including empty)
function check_ekpubhash_prefix {
	(echo "$1" | egrep -e "^[0-9a-f]*$" > /dev/null 2>&1) ||
		(echo "Error, malformed ekpubhash" >&2 && exit 1) || exit 1
}

# hostname must consist only of alphanumerics, periods ("."), hyphens ("-"),
# and underscores ("_"). TODO: our code actually allows empty hostnames, which
# is why the "_suffix" version doesn't do anything special. (The _suffix
# version certainly _should_ accept the empty case, because it's a suffix match
# for a query), but we should probably require hostnames to be non-empty, and
# probably satisfy some other sane-hostname constraints.
function check_hostname {
	(echo "$1" | egrep -e "^[0-9a-zA-Z._-]*$" > /dev/null 2>&1) ||
		(echo "Error, malformed hostname" >&2 && exit 1) || exit 1
}
function check_hostname_suffix {
	check_hostname $1
}

# We use a 3-ply directory hierarchy for storing per-TPM state, indexed by the
# "ekpubhash" of that TPM (or more accurately, the hexidecimal string
# representation of the ekpubhash in text form - 4 bits per ASCII character).
# The first ply uses the first 2 hex characters as a directory name, for a
# split of 256. The second ply uses the first 6 characters as a directory name,
# meaning 4 new characters of uniqueness for a further split of 65536,
# resulting in a total split of ~16 million. The last ply uses the first 32
# characters of the ekpubhash, with a working assumption that this (128-bits)
# is enough to establish TPM uniqueness, and no collision-handling is employed
# beyond that. That 3rd-ply (per-TPM) directory contains individual files for
# each attribute to be associated with the TPM, including 'ekpubhash' itself
# (full-length), and 'hostname'.

# Given an ekpubhash ($1), figure out the corresponding 3-ply of directories.
# Outputs;
#   PLY1, PLY2, PLY3: directory names
#   FPATH: full path
function ply_path_add {
	PLY1=`echo $1 | cut -c 1,2`
	PLY2=`echo $1 | cut -c 1-6`
	PLY3=`echo $1 | cut -c 1-32`
	FPATH="$EK_PATH/$PLY1/$PLY2/$PLY3"
}

# Given an ekpubhash prefix ($1), figure out the wildcard to match on all the
# matching per-TPM directories. (If using "ls", don't forget to use the "-d"
# switch!)
# Outputs;
#   FPATH: full path with wildcard pattern
function ply_path_get {
	len=${#1}
	if [[ $len -lt 2 ]]; then
		FPATH="$EK_PATH/$1*/*/*"
	else
		PLY1=`echo $1 | cut -c 1,2`
		if [[ $len -lt 6 ]]; then
			FPATH="$EK_PATH/$PLY1/$1*/*"
		else
			PLY2=`echo $1 | cut -c 1-6`
			if [[ $len -lt 32 ]]; then
				FPATH="$EK_PATH/$PLY1/$PLY2/$1*"
			else
				PLY3=`echo $1 | cut -c 1-32`
				FPATH="$EK_PATH/$PLY1/$PLY2/$PLY3"
			fi
		fi
	fi
}
