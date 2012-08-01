#!/bin/bash

lsbdistcodename=`lsb_release -c -s`
puppet_deb=puppetlabs-release-${lsbdistcodename}.deb
/usr/bin/wget http://apt.puppetlabs.com/$puppet_deb -O $puppet_deb
sudo dpkg -i $puppet_deb
sudo apt-get update
sudo apt-get install -y puppet git rubygems git-review

git clone https://github.com/openstack/openstack-ci-puppet
sudo bash openstack-ci-puppet/install_modules.sh

sudo puppet apply --modulepath=`pwd`/openstack-ci-puppet/modules:/etc/puppet/modules -e 'node default {class { "openstack_project::bare_slave": install_users => false }}'
