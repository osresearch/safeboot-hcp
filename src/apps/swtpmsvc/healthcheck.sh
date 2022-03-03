#/bin/bash

export PATH=$PATH:/install/bin
export LD_LIBRARY_PATH=/install/lib:$LD_LIBRARY_PATH
export TPM2TOOLS_TCTI=swtpm:path=$HCP_SWTPMSVC_TPMSOCKET

tpm2_pcrread || exit 1
