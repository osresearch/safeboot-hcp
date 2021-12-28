#!/bin/bash

. /hcp/swtpmsvc/common.sh

echo "$HCP_VER" > $HCP_SWTPMSVC_STATE_PREFIX/version

# common.sh takes care of HCP_SWTPMSVC_STATE_PREFIX and STATE_HOSTNAME. We also
# need HCP_SWTPMSVC_ENROLL_API when doing the setup.
echo "      HCP_SWTPMSVC_ENROLL_API=$HCP_SWTPMSVC_ENROLL_API" >&2

TPMDIR=$HCP_SWTPMSVC_STATE_PREFIX/tpm
mkdir $TPMDIR

echo "Setting up a software TPM for $HCP_SWTPMSVC_ENROLL_HOSTNAME"

# Initialize a software TPM
swtpm_setup --tpm2 --createek --display --tpmstate $TPMDIR --config /dev/null

# Temporarily start the TPM on an unusual port (and sleep a second to be sure
# it's alive before we hit it). TODO: Better would be to tail_wait the output.
swtpm socket --tpm2 --tpmstate dir=$TPMDIR \
	--server type=unixio,path=/throwaway \
	--ctrl type=unixio,path=/throwaway.ctrl \
	--flags startup-clear &
THEPID=$!
disown %
echo "Started temporary instance of swtpm"
sleep 1

# Now pressure it into creating the EK (and why didn't "swtpm_setup --createek"
# already achieve this?) This is natively in TPM2B_PUBLIC format, but generate
# the PEM equivalent at the same time, as this can come in handy with testing.
export TPM2TOOLS_TCTI=swtpm:path=/throwaway
tpm2 createek -c $TPMDIR/ek.ctx -u $TPMDIR/ek.pub
tpm2 print -t TPM2B_PUBLIC -f PEM $TPMDIR/ek.pub > $TPMDIR/ek.pem
chmod a+r $TPMDIR/ek.pub
chmod a+r $TPMDIR/ek.pem
echo "Software TPM state created;"
tpm2 print -t TPM2B_PUBLIC $TPMDIR/ek.pub
cat $TPMDIR/ek.pem
kill $THEPID

if [[ -n "$HCP_SWTPMSVC_ENROLL_API" ]]; then
# Now, enroll this TPM/host combination with the enrollment service.  The
# enroll_api.py script hits the API endpoint for us.
python3 /hcp/swtpmsvc/enroll_api.py --api $HCP_SWTPMSVC_ENROLL_API \
	add $TPMDIR/ek.pub $HCP_SWTPMSVC_ENROLL_HOSTNAME
fi
