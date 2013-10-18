#!/bin/bash -xe

# Copyright (C) 2011-2013 OpenStack Foundation
# Copyright (C) 2013 Hewlett-Packard Development Company, L.P.
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

mkdir -p ~/cache/files
mkdir -p ~/cache/pip
# Copied from devstack script, seems reasonable to keep and later
# build upon as needed
sudo DEBIAN_FRONTEND=noninteractive apt-get \
  --option "Dpkg::Options::=--force-confold" \
  --assume-yes install build-essential python-dev \
  linux-headers-virtual linux-headers-`uname -r`

# Might use this later for other cache, keeping for consistancy
# rm -rf ~/workspace-cache
# mkdir -p ~/workspace-cache

rm -rf ~/tripleo
mkdir -p ~/tripleo
export TRIPLEO_ROOT=~/tripleo

cd ~/tripleo
git clone https://review.openstack.org/p/openstack-infra/tripleo-ci
git clone https://review.openstack.org/p/openstack/tripleo-incubator
bash tripleo-incubator/scripts/pull-tools
# Instead of running pull-tools, we'll eventually want to get the
# refresh-env script working:
# source tripleo-incubator/scripts/refresh-env ~/tripleo

# We'll want something like this for triplo when we do dependencies
#
#. /etc/lsb-release
#cd /opt/nodepool-scripts/
#python ./devstack-cache.py $DISTRIB_CODENAME

sync
sleep 5
