#!/bin/bash -xe

# Copyright (C) 2011-2013 OpenStack Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
#
# See the License for the specific language governing permissions and
# limitations under the License.

HOSTNAME=$1
SUDO='true'
BARE='true'

/usr/bin/wget -N "http://git.openstack.org/cgit/openstack-infra/config/plain/modules/openstack_project/manifests/init.pp"
export NODEPOOL_SSH_KEY=`/bin/grep "jenkins_dev_ssh_key" init.pp | /bin/sed 's/$jenkins_dev_ssh_key = //'`

./prepare_node.sh "$HOSTNAME" "$SUDO" "$BARE"
sudo -u jenkins -i /opt/nodepool-scripts/prepare_devstack.sh $HOSTNAME

./restrict_memory.sh
