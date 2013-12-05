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

# Turn the started Ubuntu VM into a XenServer VM,
# but with an Ubuntu VM inside the XenServer VM,
# and redirect the public IP address to the Ubuntu VM.
# TODO we need to simplify this hack by making this easier in Nova
./convert_node_to_xenserver.sh

# prepare the ubuntu VM as normal
# it just happens to be running inside a XenServer VM on a XenServer
./prepare_node.sh $HOSTNAME
sudo -u jenkins -i /opt/nodepool-scripts/prepare_devstack.sh $HOSTNAME
