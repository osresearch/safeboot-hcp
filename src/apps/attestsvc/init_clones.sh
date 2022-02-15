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
waitsecs=0
waitinc=3
waitcount=0
until git clone -o origin $HCP_ATTESTSVC_REMOTE_REPO A; do
	if [[ $((++waitcount)) -eq 10 ]]; then
		echo "Error: can't clone from enrollsvc, failing" >&2
		exit 1
	fi
	if [[ $waitcount -eq 1 ]]; then
		echo "Warning: can't clone from enrollsvc, waiting" >&2
	fi
	sleep $((waitsecs+=waitinc))
	echo "Warning: retrying after $waitsecs-second wait" >&2
done
git clone -o twin A B
ln -s A current
ln -s B next
(cd A && git remote add twin ../B)
(cd B && git remote add origin $HCP_ATTESTSVC_REMOTE_REPO)
