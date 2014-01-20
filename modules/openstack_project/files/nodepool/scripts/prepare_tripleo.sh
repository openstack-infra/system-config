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
# XXX: Note that this is redundant with the cached copies in /opt/git.
# see https://bugs.launchpad.net/openstack-ci/+bug/1269889
bash /opt/git/openstack/tripleo-incubator/scripts/pull-tools
# Instead of running pull-tools, we'll eventually want to get the
# refresh-env script working:
# source tripleo-incubator/scripts/refresh-env ~/tripleo

# tripleo-gate runs with two networks - the public access network and eth1
# pointing at the in-datacentre L2 network where we can talk to the test
# environments directly. We need to enable DHCP on eth1 though.
sudo dd of=/etc/network/interfaces oflag=append conv=notrunc << EOF
auto eth1
iface eth1 inet dhcp
EOF
# Note that we don't bring it up during prepare - it's only needed to run
# tests.

# Workaround bug 1270646 for actual slaves
sudo dd of=/etc/network/interfaces.d/eth0.cfg oflag=append conv=notrunc << EOF
    post-up ip link set mtu 1458 dev eth0
EOF

# We'll want something like this for triplo when we do dependencies
#
#. /etc/lsb-release
#cd /opt/nodepool-scripts/
#python ./cache_devstack.py $DISTRIB_CODENAME

sync
sleep 5
