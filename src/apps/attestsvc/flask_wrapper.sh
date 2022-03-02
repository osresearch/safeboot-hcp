#!/bin/bash

cd /hcp/attestsvc

. common.sh

expect_hcp_user

# Convince the safeboot scripts to find safeboot.conf and functions.sh and
# the sbin stuff
export DIR=/safeboot
export BINDIR=$DIR

# Steer attest-server (and attest-verify) towards our source of truth
export SAFEBOOT_DB_DIR="$HCP_ATTESTSVC_STATE_PREFIX/current"

# Environment variable controls;
# HCP_ATTESTSVC_UWSGI
#    Specifies the UWSGI executable. If not set, the default is;
#            uwsgi_python3
# HCP_ATTESTSVC_UWSGI_FLAGS
#    Specifies the listening/interface behavior. If not set, the default is;
#            --http :$HCP_ATTESTSVC_UWSGI_PORT \
#            --stats :$((HCP_ATTESTSVC_UWSGI_PORT+1))
# HCP_ATTESTSVC_UWSGI_PORT
#    Port for UWSGI to listen on.
#    - If a port number is provided on the command-line, it takes precedence.
#    - Defaults to "8080"
#    - If HCP_ATTESTSVC_UWSGI_FLAGS is set, this variable and any port number
#      specified on the command-line are both ignored.
# HCP_ATTESTSVC_UWSGI_OPTIONS:
#    If not set, default options will be used instead;
#            --processes 2 --threads 2
#    Set to "none" if you want the cmd to use no options at all.

UWSGI=${HCP_ATTESTSVC_UWSGI:=uwsgi_python3}
PORT=${HCP_ATTESTSVC_UWSGI_PORT:=8080}
STATS=$((HCP_ATTESTSVC_UWSGI_PORT+1))
UWSGI_FLAGS=${HCP_ATTESTSVC_UWSGI_FLAGS:=--http :$HCP_ATTESTSVC_UWSGI_PORT --stats :$STATS}
UWSGI_OPTS=${HCP_ATTESTSVC_UWSGI_OPTIONS:=--processes 2 --threads 2}
[[ "$UWSGI_OPTS" == "none" ]] && UWSGI_OPTS=

# uwsgi takes SIGTERM as an indication to ... reload! So we need to translate
# SIGTERM to SIGQUIT to have the desired effect.
echo "Setting SIGTERM->SIGQUIT trap handler"
trap 'echo "Converting SIGTERM->SIGQUIT"; kill -QUIT $UPID' TERM

TO_RUN="$UWSGI \
	--plugin http \
	--wsgi-file /safeboot/sbin/attest-server \
	--callable app \
	$UWSGI_FLAGS \
	$UWSGI_OPTS"

echo "Running: $TO_RUN"
$TO_RUN &
UPID=$!
wait $UPID
