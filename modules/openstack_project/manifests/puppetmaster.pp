# == Class: openstack_project::puppetmaster
#
class openstack_project::puppetmaster (
  $root_rsa_key,
  $override_list = [],
  $sysadmins = []
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [4505, 4506, 8140],
    sysadmins                 => $sysadmins,
  }

  class { 'salt':
    salt_master => 'ci-puppetmaster.openstack.org',
  }
  class { 'salt::master': }

  cron { 'updatepuppetmaster':
    user        => 'root',
    minute      => '*/15',
    command     => 'sleep $((RANDOM\%600)) && bash /opt/config/production/run_all.sh',
    environment => 'PATH=/var/lib/gems/1.8/bin:/usr/bin:/bin:/usr/sbin:/sbin',
  }

  cron { 'deleteoldreports':
    user        => 'root',
    hour        => '3',
    minute      => '0',
    command     => 'sleep $((RANDOM\%600)) && find /var/lib/puppet/reports -name \'*.yaml\' -mtime +7 -execdir rm {} \;',
    environment => 'PATH=/var/lib/gems/1.8/bin:/usr/bin:/bin:/usr/sbin:/sbin',
  }

  file { '/etc/puppet/hiera.yaml':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    source  => 'puppet:///modules/openstack_project/puppetmaster/hiera.yaml',
    replace => true,
    require => Class['openstack_project::server'],
  }

  file { '/var/lib/puppet/reports':
    ensure => directory,
    owner  => 'puppet',
    group  => 'puppet',
    mode   => '0750',
    }

  file { '/usr/local/bin/run_remote_puppet':
    mode    => '0700',
    ensure  => present,
    content => template('openstack_project/run_remote_puppet.sh.erb'),
  }

  if ! defined(File['/root/.ssh']) {
    file { '/root/.ssh':
      ensure => directory,
      mode   => '0700',
    }
  }

  file { '/root/.ssh/id_rsa':
    ensure  => present,
    mode    => '0400',
    content => $root_rsa_key,
  }

# Cloud credentials are stored in this directory for launch-node.py.
  file { '/root/ci-launch':
    ensure => directory,
    owner  => 'root',
    group  => 'admin',
    mode   => '0750',
    }

# For launch/launch-node.py.
  package { ['python-cinderclient', 'python-novaclient']:
    ensure   => latest,
    provider => pip,
  }
  package { 'python-paramiko':
    ensure => present,
  }

# Enable puppetdb

  class { 'puppetdb::master::config':
    puppetdb_server     => 'puppetdb.openstack.org',
    puppet_service_name => 'apache2',
  }

}
