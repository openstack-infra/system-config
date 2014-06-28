# == Class: ansible
#
class ansible {

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
    source  => 'puppet:///modules/ansible/ansible.cfg',
    require => File['/etc/ansible'],
  }

  file { '/usr/local/bin/puppet-inventory':
    ensure => present,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/ansible/puppet-inventory',
  }

  file { '/usr/share/ansible/config':
    ensure  => directory,
    require => Package['ansible'],
  }

  file { '/usr/share/ansible/config/puppet':
    ensure => present,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/ansible/puppet',
  }

  file { '/usr/local/bin/puppet-inventory':
    ensure => present,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/ansible/puppet-inventory',
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
