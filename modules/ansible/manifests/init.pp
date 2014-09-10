# == Class: ansible
#
class ansible (
  $ansible_hostfile = '/usr/local/bin/puppet-inventory'
) {

  include logrotate
  include pip

  package { 'ansible':
    ensure   => latest,
    provider => pip,
  }

  if ! defined(File['/etc/ansible']) {
    file { '/etc/ansible':
      ensure  => directory,
    }
  }

  file { '/etc/ansible/ansible.cfg':
    ensure  => present,
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
    content => template('ansible/ansible.cfg.erb'),
    require => File['/etc/ansible'],
  }

  file { '/usr/local/bin/puppet-inventory':
    ensure => present,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/ansible/puppet-inventory',
  }

  file { '/etc/ansible/roles':
    ensure  => directory,
    recurse => true,
    source  => 'puppet:///modules/ansible/roles',
    require => File['/etc/ansible'],
  }

  file { '/etc/ansible/library':
    ensure  => directory,
    recurse => true,
    source  => 'puppet:///modules/ansible/library',
    require => File['/etc/ansible'],
  }

  include logrotate
  logrotate::file { 'ansible':
    log     => '/var/log/ansible.log',
    options => [
      'compress',
      'copytruncate',
      'missingok',
      'rotate 7',
      'daily',
      'notifempty',
    ],
  }

}
