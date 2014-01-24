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

rm -rf ~/workspace-cache
mkdir -p ~/workspace-cache
cd ~/workspace-cache
# XXX (lifeless) While this is redundant with the prepare_devstack
# one, we need to evolve to using /opt/git separately, so having a
# separate list makes that easier than refactoring to a single joint
# list.
git clone https://review.openstack.org/p/openstack-dev/grenade
git clone https://review.openstack.org/p/openstack-dev/pbr
git clone https://review.openstack.org/p/openstack-infra/devstack-gate
git clone https://review.openstack.org/p/openstack-infra/jeepyb
git clone https://review.openstack.org/p/openstack-infra/pypi-mirror
git clone https://review.openstack.org/p/openstack-infra/tripleo-ci
git clone https://review.openstack.org/p/openstack/ceilometer
git clone https://review.openstack.org/p/openstack/cinder
git clone https://review.openstack.org/p/openstack/diskimage-builder
git clone https://review.openstack.org/p/openstack/glance
git clone https://review.openstack.org/p/openstack/heat
git clone https://review.openstack.org/p/openstack/horizon
git clone https://review.openstack.org/p/openstack/ironic
git clone https://review.openstack.org/p/openstack/keystone
git clone https://review.openstack.org/p/openstack/neutron
git clone https://review.openstack.org/p/openstack/nova
git clone https://review.openstack.org/p/openstack/os-apply-config
git clone https://review.openstack.org/p/openstack/os-collect-config
git clone https://review.openstack.org/p/openstack/os-refresh-config
git clone https://review.openstack.org/p/openstack/oslo.config
git clone https://review.openstack.org/p/openstack/oslo.messaging
git clone https://review.openstack.org/p/openstack/python-ceilometerclient
git clone https://review.openstack.org/p/openstack/python-cinderclient
git clone https://review.openstack.org/p/openstack/python-glanceclient
git clone https://review.openstack.org/p/openstack/python-heatclient
git clone https://review.openstack.org/p/openstack/python-ironicclient
git clone https://review.openstack.org/p/openstack/python-keystoneclient
git clone https://review.openstack.org/p/openstack/python-neutronclient
git clone https://review.openstack.org/p/openstack/python-novaclient
git clone https://review.openstack.org/p/openstack/python-openstackclient
git clone https://review.openstack.org/p/openstack/python-swiftclient
git clone https://review.openstack.org/p/openstack/requirements
git clone https://review.openstack.org/p/openstack/swift
git clone https://review.openstack.org/p/openstack/tempest
git clone https://review.openstack.org/p/openstack/tripleo-heat-templates
git clone https://review.openstack.org/p/openstack/tripleo-image-elements
git clone https://review.openstack.org/p/openstack/tripleo-incubator
# and stackforge libraries we might want to test with
git clone https://review.openstack.org/p/stackforge/pecan
git clone https://review.openstack.org/p/stackforge/wsme

sync
sleep 5
