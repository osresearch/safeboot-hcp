#!/bin/bash

cd /hcp/attestsvc

. common.sh

expect_hcp_user

# Convince the safeboot scripts to find safeboot.conf and functions.sh (and the
# flask launcher to find ./sbin/attest_server_sub.py)
export DIR=/safeboot
cd $DIR

# Steer attest-server (and attest-verify) towards our source of truth
export SAFEBOOT_DB_DIR="$HCP_ATTESTSVC_STATE_PREFIX/current"

attest-server 8080
