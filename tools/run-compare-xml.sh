#!/bin/bash -e

# Copyright (c) 2012, AT&T Labs, Yun Mao <yunmao@gmail.com>
# All Rights Reserved.
# Copyright 2012 Hewlett-Packard Development Company, L.P.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

org=$1
project=$2

if [[ -z "$org" || -z "$project" ]]
then
  echo "Usage: $0 ORG PROJECT"
  echo
  echo "ORG: The project organization (eg 'openstack')"
  echo "PROJECT: The project name (eg 'nova')"
  #TODO: make fatal in subsequent change: exit 1
else
  /usr/local/jenkins/slave_scripts/select-mirror.sh $org $project
fi

rm -fr .test
mkdir .test
cd .test
git clone https://review.openstack.org/p/openstack-infra/jenkins-job-builder --depth 1
cd jenkins-job-builder
# These are $WORKSPACE/.test/jenkins-job-builder/.test/...
mkdir -p .test/old/config
mkdir -p .test/old/out
mkdir -p .test/new/config
mkdir -p .test/new/out
cd ../..

GITHEAD=`git rev-parse HEAD`

# First generate output from HEAD~1
git checkout HEAD~1
cp modules/openstack_project/files/jenkins_job_builder/config/* .test/jenkins-job-builder/.test/old/config

# Then use that as a reference to compare against HEAD
git checkout $GITHEAD
cp modules/openstack_project/files/jenkins_job_builder/config/* .test/jenkins-job-builder/.test/new/config

cd .test/jenkins-job-builder

tox -e compare-xml-old
tox -e compare-xml-new

CHANGED=0
for x in `(cd .test/old/out && find -type f)`
do
    if ! diff -u .test/old/out/$x .test/new/out/$x >/dev/null 2>&1
    then
	CHANGED=1
	echo "============================================================"
	echo $x
	echo "------------------------------------------------------------"
    fi
    diff -u .test/old/out/$x .test/new/out/$x || /bin/true
done
cd ../..

echo
echo "You are in detached HEAD mode. If you are a developer"
echo "and not very familiar with git, you might want to do"
echo "'git checkout branch-name' to go back to your branch."

if [ "$CHANGED" -eq "1" ]; then
    exit 1
fi
exit 0
