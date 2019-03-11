#!/bin/bash

curl -Lo commit-msg https://review.openstack.org/tools/hooks/commit-msg
chmod u+x ./commit-msg

cd repos
for r in $(cat ../devstack-repos.txt)
do
    git clone $r
done

for r in *
do
    pushd $r
    cp ../../commit-msg .git/hooks/
    popd
done
