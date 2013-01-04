#!/bin/bash

# Install puppet version 2.7.x from puppetlabs.
# The repo and preferences files are also managed by puppet, so be sure
# to keep them in sync with this file.

if cat /etc/*release | grep "Red Hat" &> /dev/null; then
    rpm -qi epel-release &> /dev/null || rpm -Uvh http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
    rpm -ivh http://yum.puppetlabs.com/el/6/products/x86_64/puppetlabs-release-6-6.noarch.rpm
    yum update -y
    # NOTE: enable the optional-rpms channel (if not already enabled)
    # yum-config-manager --enable rhel-6-server-optional-rpms
    yum install -y git puppet-2.7.20-1.el6.noarch
else
    #defaults to Ubuntu
    cat > /etc/apt/preferences.d/00-puppet.pref <<EOF
Package: puppet puppet-common puppetmaster puppetmaster-common
Pin: version 2.7*
Pin-Priority: 501
EOF

    lsbdistcodename=`lsb_release -c -s`
    puppet_deb=puppetlabs-release-${lsbdistcodename}.deb
    wget http://apt.puppetlabs.com/$puppet_deb -O $puppet_deb
    dpkg -i $puppet_deb
    rm $puppet_deb

    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get --option 'Dpkg::Options::=--force-confold' \
        --assume-yes upgrade
    DEBIAN_FRONTEND=noninteractive apt-get --option 'Dpkg::Options::=--force-confold' \
        --assume-yes install -y --force-yes puppet git rubygems
fi
