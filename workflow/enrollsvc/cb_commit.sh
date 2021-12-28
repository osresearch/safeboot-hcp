#!/bin/bash

# attest-enroll has called cb_checkout.sh to choose a directory for enrollment
# assets, and it then created the assets in that directory. It is now calling
# us to "commit" the results to an enrollment database, but we're bypassing the
# opportunity to do that here, and instead do it our script up top (op_add.sh),
# once attest-enroll returns.
#
# attest-enroll's prototype for COMMIT callbacks;
#   $COMMIT "$ekhash" "$outdir" "$hostname" "$DBDIR" "$CONF"
# Stdout is ignored.
