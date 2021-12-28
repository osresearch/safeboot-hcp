#!/bin/bash

. /hcp/enrollsvc/common.sh

expect_root

# Handle in-place upgrade of the next-oldest version (which is the absence of
# any version tag!).
if [[ ! -f $HCP_ENROLLSVC_STATE_PREFIX/version ]]; then
	drop_privs_db /hcp/enrollsvc/upgrade.sh
fi

# Validate that version is an exact match (obviously we need the same major,
# but right now we expect+tolerate nothing other than the same minor too).
(state_version=`cat $HCP_ENROLLSVC_STATE_PREFIX/version` &&
	[[ $state_version == $HCP_VER ]]) ||
(echo "Error: expected version $HCP_VER, but got '$state_version' instead" &&
	exit 1) || exit 1

echo "Chowning asset-signing keys for use by db_user"

chown db_user:db_user $SIGNING_KEY_PRIV $SIGNING_KEY_PUB

echo "Chowning gencert CA creds for use by db_user"

chown db_user:db_user $GENCERT_CA_PRIV $GENCERT_CA_CERT

echo "Running 'enrollsvc-mgmt' service"

drop_privs_flask /hcp/enrollsvc/flask_wrapper.sh
