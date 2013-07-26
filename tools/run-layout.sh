#!/bin/bash -e

# Copyright 2013 OpenStack Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

org=$1
project=$2

if [[ -z "$org" || -z "$project" ]]
then
  echo "Usage: $0 ORG PROJECT"
  echo
  echo "ORG: The project organization (eg 'openstack')"
  echo "PROJECT: The project name (eg 'nova')"
  exit 1
else
  /usr/local/jenkins/slave_scripts/select-mirror.sh $org $project
fi

mkdir -p .test
cd .test
[ -d zuul ] || git clone https://review.openstack.org/p/openstack-infra/zuul --depth 1
[ -d jenkins-job-builder ] || git clone https://review.openstack.org/p/openstack-infra/jenkins-job-builder --depth 1
cd jenkins-job-builder
# These are $WORKSPACE/.test/jenkins-job-builder/.test/...
mkdir -p .test/new/config
mkdir -p .test/new/out
cd ../..

cp modules/openstack_project/files/jenkins_job_builder/config/* .test/jenkins-job-builder/.test/new/config
cd .test/jenkins-job-builder
tox -e compare-xml-new

cd ..
find jenkins-job-builder/.test/new/out/ -printf "%f\n" > job-list.txt

cd zuul
tox -e venv -- zuul-server -c etc/zuul.conf-sample -l ../../modules/openstack_project/files/zuul/layout.yaml -t ../job-list.txt
