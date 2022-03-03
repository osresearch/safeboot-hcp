# This file is modeled heavily on hcp/enrollsvc/common.sh so please consult
# that for explanatory matter. (When the same comments apply here, they are
# removed.)

. /hcp/common/hcp.sh

set -e

if [[ `whoami` != "root" ]]; then
	if [[ -z "$HCP_ENVIRONMENT_SET" ]]; then
		echo "Running in reduced non-root environment (sudo probably)." >&2
		cat /etc/environment >&2
		source /etc/environment
	fi
fi

if [[ -z "$HCP_VER" ]]; then
	echo "Error, HCP_VER (\"$HCP_VER\") must be set" >&2
	exit 1
fi
mkdir -p $HCP_ATTESTSVC_STATE_PREFIX
if [[ ! -d "/home/hcp_user" ]]; then
	echo "Error, 'hcp_user' account missing or misconfigured" >&2
	exit 1
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

if [[ `whoami` == "root" ]]; then
	echo "# HCP attestsvc settings, put here so that non-root environments" >> /etc/environment
	echo "# always get known-good values." >> /etc/environment
	export_hcp_env >> /etc/environment
	echo "export HCP_ENVIRONMENT_SET=1" >> /etc/environment
fi

# Print the base configuration
echo "Running '$0'" >&2
show_hcp_env >&2

# Basic functions

function expect_root {
	if [[ `whoami` != "root" ]]; then
		echo "Error, running as \"`whoami`\" rather than \"root\"" >&2
		exit 1
	fi
}

function expect_hcp_user {
	if [[ `whoami` != "hcp_user" ]]; then
		echo "Error, running as \"`whoami`\" rather than \"hcp_user\"" >&2
		exit 1
	fi
}

function drop_privs_hcp {
	exec su -c "$*" - hcp_user
}
