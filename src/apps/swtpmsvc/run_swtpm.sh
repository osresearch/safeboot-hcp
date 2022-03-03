#!/bin/bash

. /hcp/swtpmsvc/common.sh

# Handle lazy-initialization.
if [[ ! -f $HCP_SWTPMSVC_STATE_PREFIX/initialized ]]; then
	if [[ -n $HCP_SWTPMSVC_NO_SETUP ]]; then
		echo "Error: swtpmsvc state uninitialized" >&2
		exit 1
	fi
	echo "Warning: state not initialized, initializing now" >&2
	[[ ! -d $HCP_SWTPMSVC_STATE_PREFIX ]] &&
		mkdir $HCP_SWTPMSVC_STATE_PREFIX || true
	/hcp/swtpmsvc/setup_swtpm.sh >&2
	if [[ ! -f $HCP_SWTPMSVC_STATE_PREFIX/initialized ]]; then
		echo "Error: state initialization failed" >&2
		exit 1
	fi
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

# Start the software TPM

echo "Running 'swtpmsvc' service (for $HCP_SWTPMSVC_ENROLL_HOSTNAME)"

if [[ -n "$HCP_SWTPMSVC_TPMSOCKET" ]]; then
	echo "Listening on unixio,path=$HCP_SWTPMSVC_TPMSOCKET[.ctrl]"
	exec swtpm socket --tpm2 --tpmstate dir=$HCP_SWTPMSVC_STATE_PREFIX/tpm \
		--server type=unixio,path=$HCP_SWTPMSVC_TPMSOCKET \
		--ctrl type=unixio,path=$HCP_SWTPMSVC_TPMSOCKET.ctrl \
		--flags startup-clear > /dev/null 2>&1
else
	echo "Listening on tcp,port=$TPMPORT1/$TPMPORT2"
	exec swtpm socket --tpm2 --tpmstate dir=$HCP_SWTPMSVC_STATE_PREFIX/tpm \
		--server type=tcp,bindaddr=0.0.0.0,port=$TPMPORT1 \
		--ctrl type=tcp,bindaddr=0.0.0.0,port=$TPMPORT2 \
		--flags startup-clear > /dev/null 2>&1
fi
