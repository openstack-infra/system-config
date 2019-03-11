#!/bin/bash

cd repos
for p in *
do
    echo $p
    pushd $p
    git checkout master
    branches="$(git branch -a | grep opendev-gerrit-)"
    if [[ -n "$branches" ]]; then
	for branch in $branches;
	do
	    echo "Clean $p / $branch"
	    git branch -D ${branch}
	done
    fi
    git fetch -a
    popd

done
	 
