# This is an include-only file. So no shebang header and no execute perms.

. /hcp/common/hcp.sh

set -e

# Print the base configuration
echo "Running '$0'" >&2
show_hcp_env >&2

mkdir -p $HCP_SWTPMSVC_STATE_PREFIX
if [[ -n $HCP_SWTPMSVC_TPMSOCKET_DIR ]]; then
	mkdir -p $HCP_SWTPMSVC_TPMSOCKET_DIR
fi

if [[ ! -d "/safeboot/sbin" ]]; then
	echo "Error, /safeboot/sbin is not present" >&2
	exit 1
fi
export PATH=$PATH:/safeboot/sbin
echo "Adding /safeboot/sbin to PATH" >&2

if [[ -d "/install/bin" ]]; then
	export PATH=$PATH:/install/bin
	echo "Adding /install/sbin to PATH" >&2
fi

if [[ -d "/install/lib" ]]; then
	export LD_LIBRARY_PATH=/install/lib:$LD_LIBRARY_PATH
	echo "Adding /install/lib to LD_LIBRARY_PATH" >&2
	if [[ -d /install/lib/python3/dist-packages ]]; then
		export PYTHONPATH=/install/lib/python3/dist-packages:$PYTHONPATH
		echo "Adding /install/lib/python3/dist-packages to PYTHONPATH" >&2
	fi
fi

cd $HCP_SWTPMSVC_STATE_PREFIX
