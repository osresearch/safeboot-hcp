#!/bin/bash

export DB_IN_SETUP=1

. /hcp/enrollsvc/common.sh

expect_root

# This is the one-time init hook, so make sure the mounted dir has appropriate ownership
chown $DB_USER:$DB_USER $HCP_ENROLLSVC_STATE_PREFIX

drop_privs_db /hcp/enrollsvc/init_repo.sh
