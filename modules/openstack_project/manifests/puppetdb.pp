# == Class: openstack_project::puppetdb
#
class openstack_project::puppetdb (
  $puppetboard = true,
) {

  if $puppetboard {
    class { 'openstack_project::puppetboard': }
  }
  apt::source { 'puppet-collections-1':
    comment  => 'noooo',
    location => 'http://apt.puppetlabs.com',
    release  => 'trusty',
    repos    => 'PC1',
    key      => {
      'id'     => '47B320EB4C7C375AA9DAE1A01054B7A24BD6EC30',
      'server' => 'subkeys.pgp.net',
    },
    include  => {
      'src' => false,
      'deb' => true,
    },
  }


  class { '::puppetdb::globals':
      version => '3.2.4-1puppetlabs1',
  }
  class { '::puppetdb' : 
    disable_ssl => true,
    java_args   => { '-Xmx' => '512m', '-Xms' => '256m' },
  }


}
