#!/bin/bash

# This wrapper sources the test script (at HCP_TEST_PATH) after setting a trap
# handler to clean up. It also assumes DCOMPOSE is set to invoke
# "docker-compose" with an ephemeral/unique "-p" argument, in order to keep
# any/all docker entities created by the test isolated from any other test or
# docker usage. See tests/Makefile for more detail.

if [[ -z $DCOMPOSE ]]; then
	echo "ERROR, DCOMPOSE isn't defined"
	exit 1
fi

if [[ -z $HCP_TEST_PATH ]]; then
	echo "ERROR, HCP_TEST_PATH isn't defined"
	exit 1
fi

trap '$DCOMPOSE down -v' ERR EXIT

source $HCP_TEST_PATH
