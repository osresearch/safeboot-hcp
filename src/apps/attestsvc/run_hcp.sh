#!/bin/bash

. /hcp/attestsvc/common.sh

expect_root

# Handle lazy-initialization (by waiting for the _repl sub-service to do it).
waitsecs=0
waitinc=3
waitcount=0
until [[ -f $HCP_ATTESTSVC_STATE_PREFIX/initialized ]]; do
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

# Validate that version is an exact match (obviously we need the same major,
# but right now we expect+tolerate nothing other than the same minor too).
(state_version=`cat $HCP_ATTESTSVC_STATE_PREFIX/version` &&
	[[ $state_version == $HCP_VER ]]) ||
(echo "Error: expected version $HCP_VER, but got '$state_version' instead" &&
	exit 1) || exit 1

echo "Setting SIGTERM trap handler"
trap 'kill -TERM $UPID' TERM

echo "Running 'attestsvc-hcp' service"

drop_privs_hcp /hcp/attestsvc/flask_wrapper.sh &
UPID=$!
wait $UPID
