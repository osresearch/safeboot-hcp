#!/bin/bash

set -e

# NOTES
#  - the processes started by this test do not get stopped, so attempting to
#    run it a second time will fail unless you first kill them manually.
#  - however, exiting the container will stop them, and will also destroy all
#    state.
#  - we _could_ try to wait till services are truly ready before running other
#    services that depend on them, but ... nah, let's just sleep for a second
#    instead.

# HCP Enrollment Service.
echo "Starting enrollsvc::run_mgmt.sh"
/hcp/enrollsvc/run_mgmt.sh > emgmt.stdout 2> emgmt.stderr &
echo "Starting enrollsvc::run_repl.sh"
/hcp/enrollsvc/run_repl.sh > erepl.stdout 2> erepl.stderr &

echo "Starting attestsvc::run_repl.sh"
/hcp/attestsvc/run_repl.sh > arepl.stdout 2> arepl.stderr &
echo "Starting attestsvc::run_hcp.sh"
/hcp/attestsvc/run_hcp.sh > ahcp.stdout 2> ahcp.stderr &

echo "Starting swtpmsvc::run_swtpm.sh"
/hcp/swtpmsvc/run_swtpm.sh > swtpm.stdout 2> swtpm.stderr &

echo "Starting client::run_client.sh"
/hcp/client/run_client.sh
