#!/bin/bash

. /hcp/swtpmsvc/common.sh

# Handle lazy-initialization.
if [[ ! -f $HCP_SWTPMSVC_STATE_PREFIX/initialized ]]; then
	echo "Warning: state not initialized, initializing now" >&2
	/hcp/swtpmsvc/setup_swtpm.sh >&2
	touch $HCP_SWTPMSVC_STATE_PREFIX/initialized
	echo "State now initialized" >&2
fi

TPMPORT1=9876
TPMPORT2=9877

# Validate that version is an exact match (obviously we need the same major,
# but right now we expect+tolerate nothing other than the same minor too).
(state_version=`cat $HCP_SWTPMSVC_STATE_PREFIX/version` &&
	[[ $state_version == $HCP_VER ]]) ||
(echo "Error: expected version $HCP_VER, but got '$state_version' instead" &&
	exit 1) || exit 1

echo "Running 'swtpmsvc' service (for $HCP_SWTPMSVC_ENROLL_HOSTNAME)"

# Remove sockets on exit
function cleanup_trap
{
	echo "Cleaning up sockets on exit"
	rm -f $HCP_SOCKET
	rm -f $HCP_SOCKET.ctrl
}
trap cleanup_trap EXIT

# Start the software TPM

if [[ -n "$HCP_SOCKET" ]]; then
	swtpm socket --tpm2 --tpmstate dir=$HCP_SWTPMSVC_STATE_PREFIX/tpm \
		--server type=unixio,path=$HCP_SOCKET \
		--ctrl type=unixio,path=$HCP_SOCKET.ctrl \
		--flags startup-clear > /dev/null 2>&1
else
	swtpm socket --tpm2 --tpmstate dir=$HCP_SWTPMSVC_STATE_PREFIX/tpm \
		--server type=tcp,bindaddr=0.0.0.0,port=$TPMPORT1 \
		--ctrl type=tcp,bindaddr=0.0.0.0,port=$TPMPORT2 \
		--flags startup-clear > /dev/null 2>&1
fi
