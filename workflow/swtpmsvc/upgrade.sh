#!/bin/bash

. /hcp/swtpmsvc/common.sh

cd $HCP_SWTPMSVC_STATE_PREFIX

if [[ -f version ]]; then
	echo "Error, upgrade.sh called when it shouldn't have been" >&2
	exit 1
fi

# Move everything into a "tpm/" subdirectory
mkdir tpm
mv -f ek.* tpm2-* .lock tpm/
echo "Upgraded swtpmsvc state to 1:1"
echo "1:1" > version
