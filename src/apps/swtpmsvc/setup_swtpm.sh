#!/bin/bash

. /hcp/swtpmsvc/common.sh

echo "$HCP_VER" > $HCP_SWTPMSVC_STATE_PREFIX/version

# Produce to "tpm-temp", and only move it to "tpm" if we make it all the way to
# the bottom. E.g. if the enrollsvc can't be reached within our
# retries/timeouts, we'd rather bail out with nothing than have an initialized
# swtpm that didn't enroll as promised. The trap handler removes "tpm-temp",
# which ensures we cleanup if final success wasn't achieved.
TPMDIR=$HCP_SWTPMSVC_STATE_PREFIX/tpm-temp
TPMDIR_FINAL=$HCP_SWTPMSVC_STATE_PREFIX/tpm
mkdir $TPMDIR
function trapper {
        rm -rf $TPMDIR
}
trap trapper EXIT ERR

echo "Setting up a software TPM"

# Initialize a software TPM
swtpm_setup --tpm2 --createek --tpmstate $TPMDIR --config /dev/null

# Temporarily start the TPM on an unusual port (and sleep a second to be sure
# it's alive before we hit it). TODO: Better would be to tail_wait the output.
swtpm socket --tpm2 --tpmstate dir=$TPMDIR \
	--server type=unixio,path=/throwaway \
	--ctrl type=unixio,path=/throwaway.ctrl \
	--flags startup-clear > /dev/null 2>&1 &
THEPID=$!
disown %
echo "Started temporary instance of swtpm"
sleep 1

# Now pressure it into creating the EK (and why didn't "swtpm_setup --createek"
# already achieve this?) This is natively in TPM2B_PUBLIC format, but generate
# the PEM equivalent at the same time, as this can come in handy with testing.
export TPM2TOOLS_TCTI=swtpm:path=/throwaway
tpm2 createek -c $TPMDIR/ek.ctx -u $TPMDIR/ek.pub > /dev/null 2>&1
tpm2 print -t TPM2B_PUBLIC -f PEM $TPMDIR/ek.pub > $TPMDIR/ek.pem
chmod a+r $TPMDIR/ek.pub
chmod a+r $TPMDIR/ek.pem
echo "Software TPM state created;"
cat $TPMDIR/ek.pem
kill $THEPID

if [[ -n "$HCP_SWTPMSVC_ENROLL_API" && -z "$HCP_SWTPMSVC_NO_ENROLL" ]]; then
	# Now, enroll this TPM/host combination with the enrollment service.
	# The enroll_api.py script hits the API endpoint for us.

	if [[ -z "$HCP_SWTPMSVC_ENROLL_HOSTNAME" ]]; then
		echo "Error, HCP_SWTPMSVC_ENROLL_HOSTNAME (\"$HCP_SWTPMSVC_ENROLL_HOSTNAME\") is not set" >&2
		exit 1
	fi
	echo "Enrolling swtpm hostname: $HCP_SWTPMSVC_ENROLL_HOSTNAME" >&2

	waitsecs=0
	waitinc=3
	waitcount=0
	until python3 /hcp/swtpmsvc/enroll_api.py --api $HCP_SWTPMSVC_ENROLL_API \
        	        add $TPMDIR/ek.pub $HCP_SWTPMSVC_ENROLL_HOSTNAME;
        do
		if [[ $((++waitcount)) -eq 10 ]]; then
			echo "Error: state not initialized, failing"
			exit 1
		fi
		if [[ $waitcount -eq 1 ]]; then
			echo "Warning: state not initialized, waiting"
		fi
		sleep $((waitsecs+=waitinc))
		echo "Warning: retrying after $waitsecs-second wait"
	done
        echo "Info: enrolled Software TPM at $HCP_SWTPMSVC_ENROLL_API"
fi

# Only if we get here do we move the TPM state to its final path (which means
# the trap handler won't destroy it).
mv $TPMDIR $TPMDIR_FINAL
touch $HCP_SWTPMSVC_STATE_PREFIX/initialized
