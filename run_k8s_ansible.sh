#!/bin/bash
#
# Copyright (c) 2018 Red Hat, Inc.
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
# See the License for the specific language governing permissions and
# limitations under the License.

# This file is required to wrap the ansible playbook invocation because
# we need to set config options via environment variables. There are parts
# of this that could be cleaned up upstream, but doing so makes the actual
# os_ module invocations really chatty.

cd "$(dirname "$0")"
eval $(python3 tools/cloud-to-env.py --cloud=openstackci-vexxhost --region=sjc1)

export KEY="bridge-root-2014-09-15"
export NAME="opendev-k8s"
export IMAGE="Ubuntu 16.04 LTS (x86_64) [2018-08-24]"
export MASTER_FLAVOR="v2-highcpu-4"
export MASTER_BOOT_FROM_VOLUME="True"
export IGNORE_VOLUME_AZ="True"
export FLOATING_IP_NETWORK_UUID="0048fce6-c715-4106-a810-473620326cb0"
export NODE_COUNT="4"
export NODE_FLAVOR="v2-highcpu-8"
export NODE_AUTO_IP="True"
export NODE_BOOT_FROM_VOLUME="True"
export NODE_VOLUME_SIZE="64"
export NODE_EXTRA_VOLUME="True"
export NODE_EXTRA_VOLUME_SIZE="80"
export USE_OCTAVIA="True"
export BLOCK_STORAGE_VERSION='v3'

ansible-playbook -v /opt/k8s-on-openstack/site.yaml
