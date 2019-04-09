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

# If updating the puppet system-config repo or installing puppet modules
# fails then abort the puppet run as we will not get the results we
# expect.
set -e

SYSTEM_CONFIG=/opt/system-config
ANSIBLE_PLAYBOOKS=$SYSTEM_CONFIG/playbooks

# We only send stats if running under cron
UNDER_CRON=0

while getopts ":c" arg; do
    case $arg in
        c)
            UNDER_CRON=1
            ;;
    esac
done

GLOBAL_START_TIME=$(date '+%s')

# Send a timer stat to statsd
#  send_timer metric [start_time]
# * uses timer metric bridge.ansible.run_all.<$1>
# * time will be taken from last call of start_timer, or $2 if set
function send_timer {
    # Only send stats under cron conditions
    if [[ ${UNDER_CRON} != 1 ]]; then
        return
    fi

    local current=$(date '+%s')
    local name=$1
    local start=${2-$_START_TIME}
    local elapsed_ms=$(( (current - start) * 1000 ))

    echo "bridge.ansible.run_all.${name}:${elapsed_ms}|ms" | nc -w 1 -u graphite.opendev.org 8125
    echo "End $name"
}
# See send_timer
function start_timer {
    _START_TIME=$(date '+%s')
}

echo "--- begin run @ $(date -Is) ---"

# It's possible for connectivity to a server or manifest application to break
# for indeterminate periods of time, so the playbooks should be run without
# errexit
set +e

# Run all the ansible playbooks under timeout to prevent them from getting
# stuck if they are oomkilled

# Clone system-config and install modules and roles
start_timer
timeout -k 2m 10m ansible-playbook ${ANSIBLE_PLAYBOOKS}/update-system-config.yaml
send_timer update_system_config

# Update the code on bridge
start_timer
timeout -k 2m 10m ansible-playbook ${ANSIBLE_PLAYBOOKS}/bridge.yaml
send_timer bridge

# Run k8s-on-openstack
start_timer
timeout -k 2m 120m ${SYSTEM_CONFIG}/run_k8s_ansible.sh
send_timer k8s

# Run the k8s nodes bootstrap playbook
start_timer
timeout -k 2m 120m ansible-playbook -f 50 ${ANSIBLE_PLAYBOOKS}/bootstrap-k8s-nodes.yaml
send_timer k8s_bootstrap

# Update the puppet version
# We run this before base because base enforces the specified puppet version
# but does not transition from an older version to a newer version.
# This playbook will do the transition if necessary then base will enforce
# it going forward.
start_timer
timeout -k 2m 10m ansible-playbook -f 50 ${ANSIBLE_PLAYBOOKS}/update_puppet_version.yaml
send_timer update_puppet_version

# Run the base playbook everywhere
start_timer
timeout -k 2m 120m ansible-playbook -f 50 ${ANSIBLE_PLAYBOOKS}/base.yaml
send_timer base

# These playbooks run on the gitea k8s cluster
start_timer
timeout -k 2m 10m ansible-playbook -f 50 -e @/etc/ansible/hosts/gitea-cluster.yaml ${SYSTEM_CONFIG}/kubernetes/rook/rook-playbook.yaml
send_timer gitea_rook

start_timer
timeout -k 2m 10m ansible-playbook -f 50 -e @/etc/ansible/hosts/gitea-cluster.yaml ${SYSTEM_CONFIG}/kubernetes/percona-xtradb-cluster/pxc-playbook.yaml
send_timer gitea_pxc

start_timer
timeout -k 2m 10m ansible-playbook -f 50 -e @/etc/ansible/hosts/gitea-cluster.yaml ${SYSTEM_CONFIG}/kubernetes/gitea/gitea-playbook.yaml
send_timer gitea_gitea

# Run the git/gerrit/zuul sequence, since it's important that they all work together
start_timer
timeout -k 2m 30m ansible-playbook -f 50 ${ANSIBLE_PLAYBOOKS}/remote_puppet_git.yaml
send_timer git

# Run AFS changes separately so we can make sure to only do one at a time
# (turns out quorum is nice to have)
start_timer
timeout -k 2m 30m ansible-playbook -f 1 ${ANSIBLE_PLAYBOOKS}/remote_puppet_afs.yaml
send_timer afs

# Run everything else. We do not care if the other things worked
start_timer
timeout -k 2m 30m ansible-playbook -f 50 ${ANSIBLE_PLAYBOOKS}/remote_puppet_else.yaml
send_timer else

# Send the combined time for everything
send_timer total $GLOBAL_START_TIME

echo "--- end run @ $(date -Is) ---"
echo
