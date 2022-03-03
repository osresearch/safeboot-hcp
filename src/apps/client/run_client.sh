#!/bin/bash

. /hcp/common/hcp.sh

set -e

# Print the base configuration
echo "Running '$0'"
show_hcp_env

mkdir -p $HCP_CLIENT_VERIFIER
mkdir -p $HCP_CLIENT_TPMSOCKET_DIR

if [[ -z "$HCP_CLIENT_ATTEST_URL" ]]; then
	echo "Error, HCP_CLIENT_ATTEST_URL (\"$HCP_CLIENT_ATTEST_URL\") is not set"
	exit 1
fi
if [[ -z "$HCP_CLIENT_TPM2TOOLS_TCTI" ]]; then
	echo "Error, HCP_CLIENT_TPM2TOOLS_TCTI (\"$HCP_CLIENT_TPM2TOOLS_TCTI\") is not set"
	exit 1
fi
export TPM2TOOLS_TCTI=$HCP_CLIENT_TPM2TOOLS_TCTI
if [[ -z "$HCP_CLIENT_VERIFIER" || ! -d "$HCP_CLIENT_VERIFIER" ]]; then
	echo "Error, HCP_CLIENT_VERIFIER (\"$HCP_CLIENT_VERIFIER\") is not a valid directory" >&2
	exit 1
fi
export ENROLL_SIGN_ANCHOR=$HCP_CLIENT_VERIFIER/key.pem
if [[ ! -f "$ENROLL_SIGN_ANCHOR" ]]; then
	echo "Error, HCP_CLIENT_VERIFIER does not contain key.pem" >&2
	exit 1
fi

if [[ ! -d /safeboot/sbin ]]; then
	echo "Error, Safeboot scripts aren't installed"
	exit 1
fi
export PATH=/safeboot/sbin:$PATH
echo "Adding /safeboot/sbin to PATH"

if [[ -d "/install/bin" ]]; then
	export PATH=$PATH:/install/bin
	echo "Adding /install/sbin to PATH"
fi

if [[ -d "/install/lib" ]]; then
	export LD_LIBRARY_PATH=/install/lib:$LD_LIBRARY_PATH
	echo "Adding /install/lib to LD_LIBRARY_PATH"
	if [[ -d /install/lib/python3/dist-packages ]]; then
		export PYTHONPATH=/install/lib/python3/dist-packages:$PYTHONPATH
		echo "Adding /install/lib/python3/dist-packages to PYTHONPATH"
	fi
fi

# The following helps to convince the safeboot scripts to find safeboot.conf
# and functions.sh
export DIR=/safeboot
cd $DIR

# passed in from "docker run" cmd-line
export HCP_CLIENT_TPM2TOOLS_TCTI
export HCP_CLIENT_ATTEST_URL

echo "Running 'client'"

# Check that our TPM is configured and alive
tmp_pcrread=`mktemp`
waitsecs=0
waitinc=3
waitcount=0
until tpm2_pcrread >> "$tmp_pcrread" 2>&1; do
	if [[ $((++waitcount)) -eq 6 ]]; then
		cat $tmp_pcrread >&2
		echo "Error: TPM not available, failing" >&2
		exit 1
	fi
	echo "Warning: TPM not available, waiting $((waitsecs+=waitinc)) seconds" >&2
	sleep $waitsecs
done
if [[ $waitcount -gt 0 ]]; then
	echo "Info: TPM available after retrying" >&2
fi
rm $tmp_pcrread

# TODO: this is a temporary and bad fix. The swtpm assumes that connections
# that are set up (tpm2_startup) but not gracefully terminated (tpm2_shutdown)
# are suspicious, and if it happens enough (3 or 4 times, it seems) the TPM
# locks itself to protect against possible dictionary attack. However our
# client is calling a high-level util ("tpm2-attest attest"), so it is not
# clear where tpm2_startup is happening, and it is even less clear where to add
# a matching tpm2_shutdown. Instead, we rely on the swtpm having non-zero
# tolerance to preceed each run of the client (after it has already failed at
# least once to call tpm2_shutdown), and we also rely on there being no
# dictionary policy in place to prevent us from simply resetting the suspicion
# counter!! On proper TPMs (e.g. GCE vTPM), this dictionarylockout call will
# actually fail so has to be commented out.
tpm2_dictionarylockout --clear-lockout

# Now keep trying to get a successful attestation. It may take a few seconds
# for our TPM enrollment to propagate to the attestation server, so it's normal
# for this to fail a couple of times before succeeding.
tmp_attest=`mktemp`
waitsecs=0
waitinc=3
waitcount=0
until ./sbin/tpm2-attest attest $HCP_CLIENT_ATTEST_URL \
				> secrets 2>> "$tmp_attest"; do
	if [[ $((++waitcount)) -eq 6 ]]; then
		cat $tmp_attest >&2
		echo "Error: attestation failed multiple times, giving up" >&2
		exit 1
	fi
	echo "Warning: attestation failed, may just be replication latency" >&2
	echo "Sleeping for $((waitsecs+=waitinc)) seconds" >&2
	sleep $waitsecs
done
if [[ $waitcount -gt 0 ]]; then
	echo "Info: attestation succeeded after retrying" >&2
fi
rm $tmp_attest

(
	echo "Extracting the attestation result;" && \
	tar xvf secrets && \
	echo "Signature-checking the received assets;" && \
	./sbin/tpm2-attest verify-unsealed .
) || \
(
	echo "Error of some kind." && \
	echo "Copying 'secrets' out to caller's directory for inspection" && \
	SECRETS_NAME=secrets.`date +%Y-%m-%d` && \
	echo "It will be called $SECRETS_NAME" && \
	cp secrets /escapehatch/$SECRETS_NAME && exit 1
)

echo "Client ending"
