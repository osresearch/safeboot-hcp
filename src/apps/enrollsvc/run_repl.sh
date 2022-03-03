#!/bin/bash

# To handle the case where the persistent data isn't set up, we run a subshell
# that does limited environment checks and waits for the volume to be ready.
# This follows what the mgmt container does, which launches a similar limited
# environment to _perform_ the initialization.
(
	export DB_IN_SETUP=1

	. /hcp/enrollsvc/common.sh

	expect_root

	waitsecs=0
	waitinc=3
	waitcount=0
	until [[ -f $HCP_ENROLLSVC_STATE_PREFIX/initialized ]]; do
		if [[ $((++waitcount)) -eq 10 ]]; then
			echo "Error: state not initialized, failing" >&2
			exit 1
		fi
		if [[ $waitcount -eq 1 ]]; then
			echo "Warning: state not initialized, waiting" >&2
		fi
		sleep $((waitsecs+=waitinc))
		echo "Warning: retrying after $waitsecs-second wait" >&2
	done
)

. /hcp/enrollsvc/common.sh

expect_root

# Validate that version is an exact match (obviously we need the same major,
# but right now we expect+tolerate nothing other than the same minor too).
(state_version=`cat $HCP_ENROLLSVC_STATE_PREFIX/version` &&
	[[ $state_version == $HCP_VER ]]) ||
(echo "Error: expected version $HCP_VER, but got '$state_version' instead" &&
	exit 1) || exit 1

echo "Running 'enrollsvc-repl' service (git-daemon)"

GITDAEMON=${HCP_ENROLLSVC_GITDAEMON:=/usr/lib/git-core/git-daemon}
GITDAEMON_FLAGS=${HCP_ENROLLSVC_GITDAEMON_FLAGS:=--reuseaddr --listen=0.0.0.0 --port=9418}

TO_RUN="$GITDAEMON \
	--base-path=$HCP_ENROLLSVC_STATE_PREFIX \
	$GITDAEMON_FLAGS \
	$REPO_PATH"

echo "Running (as db_user): $TO_RUN"
drop_privs_db $TO_RUN
