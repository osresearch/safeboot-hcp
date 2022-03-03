#!/bin/bash

trap '$DCOMPOSE down -v' ERR EXIT

$DCOMPOSE up -d enrollsvc_mgmt enrollsvc_repl \
		attestsvc_repl attestsvc_hcp

$DCOMPOSE run \
	-e HCP_SOAK_NUM_SWTPMS=3 \
	-e HCP_SOAK_NUM_WORKERS=1 \
	-e HCP_SOAK_NUM_LOOPS=10 \
	-e HCP_SOAK_PC_ATTEST=50 \
	caboodle_services /hcp/caboodle/soak.sh

$DCOMPOSE run \
	-e HCP_SOAK_NUM_SWTPMS=3 \
	-e HCP_SOAK_NUM_WORKERS=1 \
	-e HCP_SOAK_NUM_LOOPS=10 \
	-e HCP_SOAK_PC_ATTEST=50 \
	-e HCP_SOAK_NO_CREATE=1 \
	caboodle_services /hcp/caboodle/soak.sh
