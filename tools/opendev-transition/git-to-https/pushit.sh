#!/bin/bash

# line in format
#  repo local-branch remote-branch

cd repos
while read line;
do
    todo=($line)
    pushd ${todo[0]}
    git checkout ${todo[1]}
    if [ -n "${DOIT:-}" ]; then
	git push ssh://iwienand@review.openstack.org:29418/openstack/${todo[0]} HEAD:refs/for/${todo[2]}%topic=opendev-gerrit
    else
	echo git push ssh://iwienand@review.openstack.org:29418/openstack/${todo[0]} HEAD:refs/for/${todo[2]}%topic=opendev-gerrit
    fi
    git checkout master
    popd
done < ../to-push.txt
