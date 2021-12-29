#!/bin/bash

. /hcp/attestsvc/common.sh

expect_root

# Do common.sh-style things that are specific to the replication sub-service.
if [[ -z "$HCP_ATTESTSVC_REMOTE_REPO" ]]; then
	echo "Error, HCP_ATTESTSVC_REMOTE_REPO (\"$HCP_ATTESTSVC_REMOTE_REPO\") must be set" >&2
	exit 1
fi
if [[ -z "$HCP_ATTESTSVC_UPDATE_TIMER" ]]; then
	echo "Error, HCP_ATTESTSVC_UPDATE_TIMER (\"$HCP_ATTESTSVC_UPDATE_TIMER\") must be set" >&2
	exit 1
fi
echo "export HCP_ATTESTSVC_REMOTE_REPO=$HCP_ATTESTSVC_REMOTE_REPO" >> /etc/environment
echo "export HCP_ATTESTSVC_UPDATE_TIMER=$HCP_ATTESTSVC_UPDATE_TIMER" >> /etc/environment
echo "   HCP_ATTESTSVC_REMOTE_REPO=$HCP_ATTESTSVC_REMOTE_REPO" >&2
echo "  HCP_ATTESTSVC_UPDATE_TIMER=$HCP_ATTESTSVC_UPDATE_TIMER" >&2

# Handle lazy-initialization.
if [[ ! -f $HCP_ATTESTSVC_STATE_PREFIX/initialized ]]; then
	echo "Warning: state not initialized, initializing now" >&2
	# This is the one-time init hook, so make sure the mounted dir has
	# appropriate ownership
	chown $HCP_USER:$HCP_USER $HCP_ATTESTSVC_STATE_PREFIX
	drop_privs_hcp /hcp/attestsvc/init_clones.sh
	touch $HCP_ATTESTSVC_STATE_PREFIX/initialized
	echo "State now initialized" >&2
fi

# Validate that version is an exact match (obviously we need the same major,
# but right now we expect+tolerate nothing other than the same minor too).
(state_version=`cat $HCP_ATTESTSVC_STATE_PREFIX/version` &&
	[[ $state_version == $HCP_VER ]]) ||
(echo "Error: expected version $HCP_VER, but got '$state_version' instead" &&
	exit 1) || exit 1


echo "Running 'attestsvc-repl' service"

drop_privs_hcp /hcp/attestsvc/updater_loop.sh
