#!/bin/bash

# Copyright 2013 OpenStack Foundation.
# Copyright 2013 Hewlett-Packard Development Company, L.P.
# Copyright 2013 Red Hat, Inc.
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


# Test condition to install puppet 3
if [ "$1" = '--three' ]; then
    THREE=yes
    echo "Running in 3 mode"
fi

if cat /etc/*release | grep -e "Fedora" &> /dev/null; then
  # Fedora pre-steps
  :
else
  # Ubuntu pre-steps
  # wget isn't included on the precise lxc template
  DEBIAN_FRONTEND=noninteractive apt-get --option 'Dpkg::Options::=--force-confold' \
      --assume-yes install -y --force-yes wget
fi

# Install pip using get-pip
PIP_GET_PIP_URL=https://bootstrap.pypa.io/get-pip.py

ret=1
if [ -f ./get-pip.py ]; then
    ret=0
elif type curl >/dev/null 2>&1; then
    curl -O $PIP_GET_PIP_URL
    ret=$?
elif type wget >/dev/null 2>&1; then
    wget $PIP_GET_PIP_URL
    ret=$?
fi

if [ $ret -ne 0 ]; then
    echo "Failed to get get-pip.py"
    exit 1
fi

python get-pip.py

# Install puppet version 2.7.x or 3.x from puppetlabs.
# The repo and preferences files are also managed by puppet, so be sure
# to keep them in sync with this file.

if cat /etc/*release | grep -e "Fedora" &> /dev/null; then

    yum update -y

    # NOTE: we preinstall lsb_release to ensure facter sets lsbdistcodename
    yum install -y redhat-lsb-core git puppet


    mkdir -p /etc/puppet/modules/
    if [ "$THREE" != 'yes' ]; then
        gem install hiera hiera-puppet
        ln -s /usr/local/share/gems/gems/hiera-puppet-* /etc/puppet/modules/
    fi

    # Puppet is expecting the command to be pip-python on Fedora
    ln -s /usr/bin/pip /usr/bin/pip-python

elif cat /etc/*release | grep -e "CentOS" -e "Red Hat" &> /dev/null; then
    rpm -qi epel-release &> /dev/null || rpm -Uvh http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
    rpm -ivh http://yum.puppetlabs.com/el/6/products/x86_64/puppetlabs-release-6-6.noarch.rpm

    cat > /etc/yum.repos.d/puppetlabs.repo <<"EOF"
[puppetlabs-products]
name=Puppet Labs Products El 6 - $basearch
baseurl=http://yum.puppetlabs.com/el/6/products/$basearch
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-puppetlabs
enabled=1
gpgcheck=1
EOF

    if [ "$THREE" != 'yes' ]; then
        echo "exclude=puppet-2.8* puppet-2.9* puppet-3*" >> /etc/yum.repos.d/puppetlabs.repo
    fi

    yum update -y
    # NOTE: enable the optional-rpms channel (if not already enabled)
    # yum-config-manager --enable rhel-6-server-optional-rpms

    # NOTE: we preinstall lsb_release to ensure facter sets lsbdistcodename
    yum install -y redhat-lsb-core git puppet
else
    #defaults to Ubuntu

    lsbdistcodename=`lsb_release -c -s`
    if [ $lsbdistcodename != 'trusty' ] ; then
        rubypkg=rubygems
    else
        rubypkg=ruby
        THREE=yes
    fi

    # NB: keep in sync with openstack_project/files/00-puppet.pref
    if [ "$THREE" == 'yes' ]; then
        PUPPET_VERSION=3.*
        FACTER_VERSION=2.*
    else
        PUPPET_VERSION=2.7*
        FACTER_VERSION=1.*
    fi

    cat > /etc/apt/preferences.d/00-puppet.pref <<EOF
Package: puppet puppet-common puppetmaster puppetmaster-common puppetmaster-passenger
Pin: version $PUPPET_VERSION
Pin-Priority: 501

Package: facter
Pin: version $FACTER_VERSION
Pin-Priority: 501
EOF

    puppet_deb=puppetlabs-release-${lsbdistcodename}.deb
    wget http://apt.puppetlabs.com/$puppet_deb -O $puppet_deb
    dpkg -i $puppet_deb
    rm $puppet_deb

    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get --option 'Dpkg::Options::=--force-confold' \
        --assume-yes dist-upgrade
    DEBIAN_FRONTEND=noninteractive apt-get --option 'Dpkg::Options::=--force-confold' \
        --assume-yes install -y --force-yes puppet git $rubypkg
fi
