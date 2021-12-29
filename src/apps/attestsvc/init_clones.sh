#!/bin/bash

. /hcp/attestsvc/common.sh

expect_hcp_user

cd $HCP_ATTESTSVC_STATE_PREFIX

echo "$HCP_VER" > version

if [[ -d A || -d B || -h current || -h next || -h thirdwheel ]]; then
	echo "Error, updater state half-baked?" >&2
	exit 1
fi

echo "First-time initialization of $HCP_ATTESTSVC_STATE_PREFIX. Two clones and two symlinks." >&2
git clone $HCP_ATTESTSVC_REMOTE_REPO A
git clone $HCP_ATTESTSVC_REMOTE_REPO B
ln -s A current
ln -s B next
(cd A && git remote add twin ../B && git fetch twin)
(cd B && git remote add twin ../A && git fetch twin)
