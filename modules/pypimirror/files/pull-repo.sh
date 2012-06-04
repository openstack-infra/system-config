#!/bin/bash
# This file is managed by puppet.
# https://github.com/openstack/openstack-ci-puppet

export PIP_DOWNLOAD_CACHE=${PIP_DOWNLOAD_CACHE:-/var/cache/pip}
export PIP_TEMP_DOWNLOAD=${PIP_TEMP_DOWNLOAD:-/var/lib/pip-download}

project=$1
pip_command='pip install -M -U -I --exists-action=w --no-install'

cd ${PIP_TEMP_DOWNLOAD}
if [ ! -d ${project} ] ; then
  git clone git://github.com/openstack/${project}.git ${project} >/dev/null 2>&1
fi
cd ${project}
git fetch origin
for branch in `git branch -a | grep remotes.origin | grep -v origin.HEAD | awk '{print $1}' ` ; do
    git reset --hard $branch
    git clean -x -f -d -q
    echo "*********************"
    echo "Fetching pip requires for $project:$branch"
    for requires_file in tools/pip-requires tools/test-requires ; do
        if [ -f ${requires_file} ] ; then
            $pip_command -r $requires_file 
        fi
    done
done
