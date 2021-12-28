#!/bin/bash

# NB: this query logic is transformed into delete logic by the presence of
# QUERY_PLEASE_ALSO_DELETE.

. /hcp/enrollsvc/common.sh

expect_db_user

echo "Starting $0" >&2
echo "  - Param1=$1 (ekpubhash)" >&2

check_ekpubhash_prefix "$1"

cd $REPO_PATH

ply_path_get "$1"

# The JSON output should look like;
#    {
#        "entries": [
#            {
#                "ekpubhash": "abbaf00ddeadbeef"
#                "hostname": "host-at.some_domain.com"
#                "others": [
#                    "hostname-some.other.fqdn",
#                    "hostname-and.one.more",
#                    "meta-data",
#                    "rootfs.key.enc",
#                    "rootfs.key.symkeyenc",
#                    "user-data",
#                    "ssh-server-key"
#                ]
#            }
#            ,
#            {
#                "ekpubhash": "0123456789abcdef"
#                "hostname": "whatever.wherever.foo"
#                "others": [
#                ]
#            }
#        ]
#    }

repo_cmd_lock || (echo "Error, failed to lock repo" >&2 && exit 1) || exit 1

# TODO: as noted in common.sh, the hn2ek implementation is crude and won't
# have fantastic scalability.

# If we're deleting, we build up a filter list of "rev(hostname) ekpubhash"
# strings as we remove the corresponding directories. At the conclusion, we
# filter this list out of the hn2ek (reverse-lookup) table.
[[ -z $QUERY_PLEASE_ALSO_DELETE ]] || cat /dev/null > $HN2EK_PATH.filter ||
	(echo "Error, failed to create pattern tracker" >&2 && exit 1) ||
	itfailed=1

# Iterate over the matching directories in the ekpubhash tree. Each directory
# path is cat'd to stdout and, _if we're deleting_, we also;
# (a) add a corresponding line to the filter list. This is formed by;
#     - reading the "hostname" file from the directory,
#     - reversing it,
#     - adding the ekpubhash (after a space-separator),
# (b) "git rm" the directory.
[[ -z $itfailed ]] &&
(
DIR_LIST=`ls -d $FPATH 2> /dev/null`
for i in $DIR_LIST; do
	read ekp < $i/ekpubhash
	read hn < $i/hostname
	[[ -z $QUERY_PLEASE_ALSO_DELETE ]] ||
		(revhn=`echo $hn | rev` &&
		echo $revhn `basename "$i"` >> $HN2EK_PATH.filter) ||
		(echo "Error, failed to add filter" >&2 && exit 1) ||
		exit 1
	ls -1 $i | grep -v "ekpubhash" | grep -v "hostname" | \
		jq -Rn \
		--arg ekpubhash "$ekp" \
		--arg hostname "$hn" \
		'{ekpubhash: $ekpubhash, hostname: $hostname, others: [inputs]}'
	[[ -z $QUERY_PLEASE_ALSO_DELETE ]] || git rm -r $i >&2 ||
		(echo "Error, 'git rm'/pattern-tracker failed" >&2 && exit 1) ||
		exit 1
done
) | jq -n '{entries: [inputs]}' || itfailed=1

# If we haven't yet failed, and we're deleting, and we saw at least one entry
# to be deleted, then filter the deleted entries out of the hn2ek table.
[[ -s $HN2EK_PATH.filter ]] && ATLEAST1=1
if [[ -z $itfailed ]] && [[ -n $QUERY_PLEASE_ALSO_DELETE ]] && [[ -n $ATLEAST1 ]]; then
	(grep -F -v -f $HN2EK_PATH.filter $HN2EK_PATH > $HN2EK_PATH.new || /bin/true) &&
	mv $HN2EK_PATH.new $HN2EK_PATH &&
	rm $HN2EK_PATH.filter ||
	(echo "Error, hn2ek filtering failed" >&2 && exit 1) || itfailed=1
fi

# Same criteria again. We add the hn2ek table to the list of modifications to
# commit and make the commit
if [[ -z $itfailed ]] && [[ -n $QUERY_PLEASE_ALSO_DELETE ]] && [[ -n $ATLEAST1 ]]; then
	git add $HN2EK_PATH >&2 &&
	git commit -m "delete $1" >&2 ||
	(echo "Error, commiting failed" >&2 && exit 1) || itfailed=1
fi

# TODO: Same comment and same code as in op_add.sh - I won't repeat it here.
[[ -z $itfailed ]] ||
	(echo "Failure, attempting recovery" >&2 &&
		echo "running 'git reset --hard'" >&2 && git reset --hard &&
		echo "running 'git clean -f -d -x'" >&2 && git clean -f -d -x) ||
	rollbackfailed=1

[[ -z "$rollbackfailed" ]] && repo_cmd_unlock

# If it failed, fail
[[ -n "$itfailed" ]] && exit 1
/bin/true
