#!/bin/bash -xe

# Make sure there is a location on this builder to cache pip downloads
mkdir -p ~/cache/pip
export PIP_DOWNLOAD_CACHE=~/cache/pip

# Start with a clean slate
rm -fr jenkins_venvs
mkdir -p jenkins_venvs

# Build a venv for every known branch
for branch in `git branch -r |grep "origin/"|grep -v HEAD|sed "s/origin\///"`
do
    echo "Building venv for $branch"
    git checkout $branch
    mkdir -p jenkins_venvs/$branch
    bundle=jenkins_venvs/$branch/.cache.bundle

    if [ -f tools/pip-requires ] ; then
        if [ -f tools/test-requires ] ; then
            pip bundle $bundle -r tools/pip-requires -r tools/test-requires
        else
            pip bundle $bundle -r tools/pip-requires
        fi
    else
        pip bundle $bundle distribute openstack.nose_plugin
    fi
done
git checkout master
