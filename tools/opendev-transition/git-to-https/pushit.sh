#!/bin/bash

# line in format
#  repo local-branch remote-branch

cd repos
while read line;
do
    todo=($line)
    pushd ${todo[0]}
    full_project=$(cat .gitreview | grep 'project=' | sed 's/project=//')
    git checkout ${todo[1]}
    if [ -n "${DOIT:-}" ]; then
	git push ssh://iwienand@review.openstack.org:29418/${full_project} HEAD:refs/for/${todo[2]}%topic=opendev-gerrit-git
    else
	echo git push ssh://iwienand@review.openstack.org:29418/${full_project} HEAD:refs/for/${todo[2]}%topic=opendev-gerrit-git
    fi
    git checkout master
    popd
done < ../to-push.txt
