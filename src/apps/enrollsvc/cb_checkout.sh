#!/bin/bash

# Safeboot's "attest-enroll" script makes some default assumptions that we'd
# rather side-step. We use the CHECKOUT and COMMIT hooks to override the
# relevant handling. This file is the CHECKOUT hook, and is expected to print
# to stdout the path that the enrolled output should be generated to.
#
# attest-enroll's prototype for CHECKOUT callbacks;
#   $CHECKOUT "$ekhash" "$hostname" "$DBDIR" "$CONF"
# Stdout is assumed to be the directory where enrollment will occur.
#
# In our usage here, the op_add.sh script sets EPHEMERAL_ENROLL to a
# (temporary) location where it wants the enrollment outcomes to go, and points
# CHECKOUT to this script before invoking attest-enroll. We just have to echo
# the path op_add.sh passed to us, and don't use any of the callback arguments.

[[ -z "$EPHEMERAL_ENROLL" ]] && exit 1
echo "$EPHEMERAL_ENROLL"
