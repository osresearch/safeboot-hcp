#!/bin/bash

. /hcp/enrollsvc/common.sh

expect_db_user

cd $HCP_ENROLLSVC_STATE_PREFIX

if [[ -f version ]]; then
	echo "Error, upgrade.sh called when it shouldn't have been" >&2
	exit 1
fi

# This function will run on all exit paths, successful and otherwise. It makes
# the upgrade transactional - by putting the tree back into the state matching
# the head of the branch. I.e. if the commit happened, this confirms it with no
# side-effect, otherwise it causes a rollback.
function cleanup_trap
{
	cd $REPO_PATH
	git reset --hard
	git clean -f -d -x
}
trap cleanup_trap EXIT

# Now do the upgrade. First the version inside the git repo, then the version
# outside it.
cd $REPO_PATH
echo "1:1" > version
git add version
git commit -m "In-place upgrade to version 1:1"
cd $HCP_ENROLLSVC_STATE_PREFIX
echo "1:1" > version
