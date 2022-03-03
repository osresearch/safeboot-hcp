#!/bin/bash

. /hcp/caboodle/hcp.sh

# we only start/stop services if HCP_CABOODLE_ALONE is set, and even then, only
# if the user hasn't been starting/stopping things themselves!
if [[ -n $HCP_CABOODLE_ALONE ]] && ! hcp_services_any_started; then
	echo "Automatically starting/stopping services"
	trap hcp_services_stop EXIT ERR
	hcp_services_start || exit 1
fi

echo "Starting client::run_client.sh"
/hcp/client/run_client.sh > client.out 2>&1 ||
(
	echo "Hmmm, client failed. Dumping output;"
	cat client.out
	echo "Sleeping $HCP_CABOODLE_SLEEP_IF_FAIL seconds"
	echo "(perhaps use 'docker[-compose] exec [...]' to inspect)"
	sleep $HCP_CABOODLE_SLEEP_IF_FAIL
	exit 1
)

echo "Success"
