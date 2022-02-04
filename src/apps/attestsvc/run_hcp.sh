#!/bin/bash

. /hcp/attestsvc/common.sh

expect_root

# Handle lazy-initialization (by waiting for the _repl sub-service to do it).
if [[ ! -f $HCP_ATTESTSVC_STATE_PREFIX/initialized ]]; then
	echo "Warning: state not initialized, waiting" >&2
	sleep 10
	if [[ ! -f $HCP_ATTESTSVC_STATE_PREFIX/initialized ]]; then
		echo "Error: state not initialized, failing" >&2
		exit 1
	fi
	echo "State now initialized" >&2
fi

# Validate that version is an exact match (obviously we need the same major,
# but right now we expect+tolerate nothing other than the same minor too).
(state_version=`cat $HCP_ATTESTSVC_STATE_PREFIX/version` &&
	[[ $state_version == $HCP_VER ]]) ||
(echo "Error: expected version $HCP_VER, but got '$state_version' instead" &&
	exit 1) || exit 1

echo "Running 'attestsvc-hcp' service"

drop_privs_hcp /hcp/attestsvc/flask_wrapper.sh
