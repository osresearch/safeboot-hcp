#!/bin/bash

$DCOMPOSE up -d enrollsvc_mgmt enrollsvc_repl \
		attestsvc_repl attestsvc_hcp

$DCOMPOSE run caboodle_services /hcp/caboodle/soak.sh

