#!/bin/bash

cat > /etc/apt/preferences.d/00-puppet.pref <<EOF
Package: puppet puppet-common puppetmaster puppetmaster-common
Pin: version 2.7*
Pin-Priority: 501
EOF

lsbdistcodename=`lsb_release -c -s`
puppet_deb=puppetlabs-release-${lsbdistcodename}.deb
wget http://apt.puppetlabs.com/$puppet_deb -O $puppet_deb
dpkg -i $puppet_deb

apt-get update
apt-get install -y puppet git rubygems

git clone https://github.com/openstack/openstack-ci-puppet
bash openstack-ci-puppet/install_modules.sh

puppet apply --modulepath=`pwd`/openstack-ci-puppet/modules:/etc/puppet/modules -e 'node default {class { "openstack_project::bare_slave": install_users => false }}'
