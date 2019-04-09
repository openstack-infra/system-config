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
export ANSIBLE_LOG_PATH=/var/log/puppet_run_cloud_launcher.log
SYSTEM_CONFIG=/opt/system-config
ANSIBLE_PLAYBOOKS=$SYSTEM_CONFIG/playbooks

# It's possible for connectivity to a server or manifest application to break
# for indeterminate periods of time, so the playbooks should be run without
# errexit
set +e

# We only send stats if running under cron
UNDER_CRON=0

while getopts ":c" arg; do
    case $arg in
        c)
            UNDER_CRON=1
            ;;
    esac
done

_START_TIME=$(date '+%s')

echo "--- begin run @ $(date -Is) ---"

# We need access to all-clouds
export OS_CLIENT_CONFIG_FILE=/etc/openstack/all-clouds.yaml

# Pass -i /dev/null to avoid the ansible-playbook run with all-clouds.yaml
# being active messing with the normal inventory cache.
/usr/bin/timeout -k 2m 120m /usr/local/bin/ansible-playbook -i /dev/null -f 1 \
    ${ANSIBLE_PLAYBOOKS}/run_cloud_launcher.yaml \
    -e@${ANSIBLE_PLAYBOOKS}/clouds_layouts.yml

echo "--- end run @ $(date -Is) ---"

# Only send stats under cron conditions
if [[ ${UNDER_CRON} != 1 ]]; then
    return
fi

_CURRENT_TIME=$(date '+%s')
_ELAPSED_MS=$(( (_CURRENT_TIME - _START_TIME) * 1000 ))
echo "bridge.ansible.run_cloud_launcher:${_ELAPSED_MS}|ms" | \
    nc -w 1 -u graphite.opendev.org 8125
