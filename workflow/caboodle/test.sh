#!/bin/bash

set -e

# NOTES
#  - the processes started by this test do not get stopped, so attempting to
#    run it a second time will fail unless you first kill them manually.
#  - however, exiting the container will stop them, and will also destroy all
#    state.

# HCP Enrollment Service.
/hcp/enrollsvc/setup_enrolldb.sh
/hcp/enrollsvc/run_mgmt.sh &
/hcp/enrollsvc/run_repl.sh &

# We _could_ tail_wait.pt the enrollsvc msgbus outputs to make sure they're
# truly listening before we launch things (like attestsvc) that depend on it.
# But ... nah. Let's just sleep for a second instead.
sleep 1

/hcp/attestsvc/setup_repl.sh
/hcp/attestsvc/run_repl.sh &
/hcp/attestsvc/run_hcp.sh &

# Same comment;
sleep 1

/hcp/swtpmsvc/setup_swtpm.sh
/hcp/swtpmsvc/run_swtpm.sh &

# Same comment;
sleep 1

/hcp/client/run_client.sh
