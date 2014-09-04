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

#
# Distro identification functions
#  note, can't rely on lsb_release for these as we're bare-bones and
#  it may not be installed yet)

#
# Test condition to install puppet 3
PUPPET_VERSION=${PUPPET_VERSION:-2}
if [ "$PUPPET_VERSION" = '3' ]; then
    THREE=yes
    echo "Running in 3 mode"
fi

#
# Distro identification functions
#  note, can't rely on lsb_release for these as we're bare-bones and
#  it may not be installed yet)


function is_fedora {
    [ -f /usr/bin/yum ] && cat /etc/*release | grep -q -e "Fedora"
}

function is_rhel6 {
    [ -f /usr/bin/yum ] && \
        cat /etc/*release | grep -q -e "Red Hat" -e "CentOS" && \
        cat /etc/*release | grep -q 'release 6'
}

function is_rhel7 {
    [ -f /usr/bin/yum ] && \
        cat /etc/*release | grep -q -e "Red Hat" -e "CentOS" && \
        cat /etc/*release | grep -q 'release 7'
}

function is_ubuntu {
    [ -f /usr/bin/apt-get ]
}


#
# Distro specific puppet installs
#

function setup_puppet_fedora {
    yum update -y

    # NOTE: we preinstall lsb_release to ensure facter sets
    # lsbdistcodename
    yum install -y redhat-lsb-core git puppet


    mkdir -p /etc/puppet/modules/
    if [ "$THREE" != 'yes' ]; then
        gem install hiera hiera-puppet
        ln -s /usr/local/share/gems/gems/hiera-puppet-* /etc/puppet/modules/
    fi

    # Puppet expects the pip command named as pip-python on
    # Fedora, as per the packaged command name.  However, we're
    # installing from get-pip.py so it's just 'pip'.  An easy
    # work-around is to just symlink pip-python to "fool" it.
    # See upstream issue:
    #  https://tickets.puppetlabs.com/browse/PUP-1082
    ln -fs /usr/bin/pip /usr/bin/pip-python
}

function setup_puppet_rhel7 {

    local epel_pkg="http://dl.fedoraproject.org/pub/epel/beta/7/x86_64/epel-release-7-0.2.noarch.rpm"
    local puppet_pkg="https://yum.puppetlabs.com/el/7/products/x86_64/puppetlabs-release-7-10.noarch.rpm"

    # install EPEL
    rpm -qi epel-release &> /dev/null || rpm -Uvh $epel_pkg

    # NOTE: we preinstall lsb_release to ensure facter sets lsbdistcodename
    yum install -y redhat-lsb-core git puppet

    rpm -ivh $puppet_pkg

    # see comments in setup_puppet_fedora
    ln -s /usr/bin/pip /usr/bin/pip-python
}

function setup_puppet_rhel6 {
    local epel_pkg="http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm"
    local puppet_pkg="http://yum.puppetlabs.com/el/6/products/x86_64/puppetlabs-release-6-6.noarch.rpm"

    # install EPEL
    rpm -qi epel-release &> /dev/null || rpm -Uvh $epel_pkg
    # NOTE: for RHEL (not CentOS) enable the optional-rpms channel (if
    # not already enabled)
    # yum-config-manager --enable rhel-6-server-optional-rpms

    # NOTE: we preinstall lsb_release to ensure facter sets lsbdistcodename
    yum install -y redhat-lsb-core git puppet

    rpm -ivh $puppet_pkg

    # ensure we stick to supported puppet 2 versions
    cat > /etc/yum.repos.d/puppetlabs.repo <<"EOF"
[puppetlabs-products]
name=Puppet Labs Products El 6 - $basearch
baseurl=http://yum.puppetlabs.com/el/6/products/$basearch
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-puppetlabs
enabled=1
gpgcheck=1
EOF

    if [ "$THREE" != 'yes' ]; then
        echo 'exclude=puppet-2.8* puppet-2.9* puppet-3* facter-2*' >> /etc/yum.repos.d/puppetlabs.repo
    fi

    yum update -y
}

function setup_puppet_ubuntu {
    if ! which lsb_release > /dev/null 2<&1 ; then
      DEBIAN_FRONTEND=noninteractive apt-get --option 'Dpkg::Options::=--force-confold' \
        --assume-yes install -y --force-yes lsb-release
    fi

    lsbdistcodename=`lsb_release -c -s`
    if [ $lsbdistcodename != 'trusty' ] ; then
        rubypkg=rubygems
    else
        rubypkg=ruby
        THREE=yes
    fi

    # NB: keep in sync with openstack_project/files/00-puppet.pref
    if [ "$THREE" == 'yes' ]; then
        PUPPET_VERSION=3.4.*
        FACTER_VERSION=2.*
    else
        PUPPET_VERSION=2.7*
        FACTER_VERSION=1.*
    fi

    cat > /etc/apt/preferences.d/00-puppet.pref <<EOF
Package: puppet puppet-common puppetmaster puppetmaster-common puppetmaster-passenger puppetdb-terminus
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
}

#
# pip setup
#

function setup_pip {
    # Install pip using get-pip
    local get_pip_url=https://bootstrap.pypa.io/get-pip.py
    local ret=1

    if [ -f ./get-pip.py ]; then
        ret=0
    elif type curl >/dev/null 2>&1; then
        curl -O $get_pip_url
        ret=$?
    elif type wget >/dev/null 2>&1; then
        wget $get_pip_url
        ret=$?
    fi

    if [ $ret -ne 0 ]; then
        echo "Failed to get get-pip.py"
        exit 1
    fi

    if is_rhel6; then
        yum erase -y python-setuptools
        rm -rf /usr/lib/python2.6/site-packages/setuptools*
    fi

    python get-pip.py
    pip install -U setuptools
}

#
# Install pip & puppet
#

setup_pip

if is_fedora; then
    setup_puppet_fedora
elif is_rhel6; then
    setup_puppet_rhel6
elif is_rhel7; then
    setup_puppet_rhel7
elif is_ubuntu; then
    setup_puppet_ubuntu
else
    echo "*** Can not setup puppet: distribution not recognized"
    exit 1
fi
