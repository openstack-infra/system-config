#!/bin/bash

# Copyright 2014 Hewlett-Packard Development Company, L.P.
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

# Tell graphite that we are starting to deploy
echo "puppetmaster.deploy_state:1|g" | nc -u -w0 graphite.openstack.org 8125
start_time=`date +%s`

# If updating the puppet system-config repo or installing puppet modules
# fails then abort the puppet run as we will not get the results we
# expect.
set -e
export ANSIBLE_LOG_PATH=/var/log/puppet_run_all.log
SYSTEM_CONFIG=/opt/system-config/production
ANSIBLE_PLAYBOOKS=$SYSTEM_CONFIG/playbooks

# It's possible for connectivity to a server or manifest application to break
# for indeterminate periods of time, so the playbooks should be run without
# errexit
set +e

# Run all the ansible playbooks under timeout to prevent them from getting
# stuck if they are oomkilled

# First, sync the puppet repos with all the machines
timeout -k 2m 120m ansible-playbook -f 10 ${ANSIBLE_PLAYBOOKS}/update_puppet.yaml
# Run the git/gerrit sequence, since it's important that they all work together
timeout -k 2m 120m ansible-playbook -f 10 ${ANSIBLE_PLAYBOOKS}/remote_puppet_git.yaml
# Run AFS changes separately so we can make sure to only do one at a time
# (turns out quorum is nice to have)
timeout -k 2m 120m ansible-playbook -f 1 ${ANSIBLE_PLAYBOOKS}/remote_puppet_afs.yaml
# Run everything else. We do not care if the other things worked
timeout -k 2m 120m ansible-playbook -f 10 ${ANSIBLE_PLAYBOOKS}/remote_puppet_else.yaml

# Tell graphite that we are done deploying
echo "puppetmaster.deploy_state:0|g" | nc -u -w0 graphite.openstack.org 8125
end_time=`date +%s`
total_time=`echo $end_time - $start_time | bc`
echo "puppetmaster.deploy_time:${total_time}|t" | nc -u -w0 graphite.openstack.org 8125

