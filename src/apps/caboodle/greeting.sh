#!/bin/bash

echo "==============================================="

[[ -n $HCP_CABOODLE_ALONE ]] &&
(
echo "Interactive 'caboodle' session, for autonomous operation."
echo "I.e. the configuration variables are set for tools and tests to"
echo "expect/find HCP services running locally within this container."
echo ""
echo "To start/stop the HCP services within this container;"
echo "    hcp_services_start"
echo "    hcp_services_stop"
echo "Or by hand;"
echo "    /hcp/enrollsvc/run_mgmt.sh > /logs/enrollsvc_mgmt 2>&1 &"
echo "    /hcp/enrollsvc/run_repl.sh > /logs/enrollsvc_repl 2>&1 &"
echo "    /hcp/attestsvc/run_repl.sh > /logs/attestsvc_repl 2>&1 &"
echo "    /hcp/attestsvc/run_hcp.sh > /logs/attestsvc_hcp 2>&1 &"
echo "    /hcp/swtpmsvc/run_swtpm.sh > /logs/swtpmsvc 2>&1 &"
) ||
(
echo "Interactive 'caboodle' session for working with service containers."
echo "I.e. configuration variables are set for tools and tests to"
echo "expect/find those services running in distinct containers."
)
echo ""
echo "To run the attestation test;"
echo "    /hcp/caboodle/test.sh"
echo ""
echo "To run the soak-test (which creates its own software TPMs);"
echo "    /hcp/caboodle/soak.sh"
echo "using these (overridable) settings;"
echo "    HCP_SOAK_PREFIX (default: $HCP_SOAK_PREFIX)"
echo "    HCP_SOAK_NUM_SWTPMS (default: $HCP_SOAK_NUM_SWTPMS)"
echo "    HCP_SOAK_NUM_WORKERS (default: $HCP_SOAK_NUM_WORKERS)"
echo "    HCP_SOAK_NUM_LOOPS (default: $HCP_SOAK_NUM_LOOPS)"
echo "    HCP_SOAK_PC_ATTEST (default: $HCP_SOAK_PC_ATTEST)"
echo "    HCP_SOAK_NO_CREATE (default: $HCP_SOAK_NO_CREATE)"
echo ""
echo "To view or export the HCP environment variables;"
echo "    show_hcp_env"
echo "    export_hcp_env"
echo "==============================================="
