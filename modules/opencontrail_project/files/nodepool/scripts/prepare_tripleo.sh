#!/bin/bash -xe

# Copyright (C) 2011-2013 OpenContrail Foundation
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

# Enable precise-backports so we can install jq
sudo sed -i -e 's/# \(deb .*precise-backports main \)/\1/g' /etc/apt/sources.list
sudo apt-get update

# Copied from devstack script, seems reasonable to keep and later
# build upon as needed
sudo DEBIAN_FRONTEND=noninteractive apt-get \
  --option "Dpkg::Options::=--force-confold" \
  --assume-yes install build-essential python-dev python-pip \
  linux-headers-virtual linux-headers-`uname -r` \
  libffi-dev

# toci scripts use both of these
sudo pip install gear os-apply-config

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
git clone https://review.opencontrail.org/p/opencontrail-dev/grenade
git clone https://review.opencontrail.org/p/opencontrail-dev/pbr
git clone https://review.opencontrail.org/p/opencontrail-infra/devstack-gate
git clone https://review.opencontrail.org/p/opencontrail-infra/jeepyb
git clone https://review.opencontrail.org/p/opencontrail-infra/pypi-mirror
git clone https://review.opencontrail.org/p/opencontrail-infra/tripleo-ci
git clone https://review.opencontrail.org/p/opencontrail/ceilometer
git clone https://review.opencontrail.org/p/opencontrail/cinder
git clone https://review.opencontrail.org/p/opencontrail/diskimage-builder
git clone https://review.opencontrail.org/p/opencontrail/glance
git clone https://review.opencontrail.org/p/opencontrail/heat
git clone https://review.opencontrail.org/p/opencontrail/horizon
git clone https://review.opencontrail.org/p/opencontrail/ironic
git clone https://review.opencontrail.org/p/opencontrail/keystone
git clone https://review.opencontrail.org/p/opencontrail/neutron
git clone https://review.opencontrail.org/p/opencontrail/nova
git clone https://review.opencontrail.org/p/opencontrail/os-apply-config
git clone https://review.opencontrail.org/p/opencontrail/os-collect-config
git clone https://review.opencontrail.org/p/opencontrail/os-refresh-config
git clone https://review.opencontrail.org/p/opencontrail/oslo.config
git clone https://review.opencontrail.org/p/opencontrail/oslo.messaging
git clone https://review.opencontrail.org/p/opencontrail/python-ceilometerclient
git clone https://review.opencontrail.org/p/opencontrail/python-cinderclient
git clone https://review.opencontrail.org/p/opencontrail/python-glanceclient
git clone https://review.opencontrail.org/p/opencontrail/python-heatclient
git clone https://review.opencontrail.org/p/opencontrail/python-ironicclient
git clone https://review.opencontrail.org/p/opencontrail/python-keystoneclient
git clone https://review.opencontrail.org/p/opencontrail/python-neutronclient
git clone https://review.opencontrail.org/p/opencontrail/python-novaclient
git clone https://review.opencontrail.org/p/opencontrail/python-opencontrailclient
git clone https://review.opencontrail.org/p/opencontrail/python-swiftclient
git clone https://review.opencontrail.org/p/opencontrail/requirements
git clone https://review.opencontrail.org/p/opencontrail/swift
git clone https://review.opencontrail.org/p/opencontrail/tempest
git clone https://review.opencontrail.org/p/opencontrail/tripleo-heat-templates
git clone https://review.opencontrail.org/p/opencontrail/tripleo-image-elements
git clone https://review.opencontrail.org/p/opencontrail/tripleo-incubator
# and stackforge libraries we might want to test with
git clone https://review.opencontrail.org/p/stackforge/pecan
git clone https://review.opencontrail.org/p/stackforge/wsme

sync
sleep 5
