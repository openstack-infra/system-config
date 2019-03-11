#!/bin/bash

cd repos
for p in *
do
    echo $p
    pushd $p
    git checkout master
    git branch -D opendev-gerrit
    popd
done
	 
