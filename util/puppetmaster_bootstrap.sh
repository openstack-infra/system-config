#!/bin/bash
set -x

apt-get update
apt-get install git
git clone https://git.openstack.org/openstack-infra/config

cd config

cat > manifests/local.pp <<EOF
node default {
  class { 'openstack_project::puppetmaster':
    root_rsa_key => hiera('puppetmaster_root_rsa_key', 'XXX'),
    update_slave => false,
    sysadmins    => hiera('sysadmins', []),
    version      => '3.6.',
    ca_server    => 'ci-puppetmaster.openstack.org',
    puppetdb     => false,
  }
}
EOF

export PUPPET_VERSION=3
./install_puppet.sh
./install_modules.sh
puppet apply  --modulepath=modules:/etc/puppet/modules manifests/local.pp

