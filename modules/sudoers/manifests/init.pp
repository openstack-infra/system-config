# == Class: sudoers
#
class sudoers {
  group { 'sudo':
    ensure => present,
  }
  group { 'admin':
    ensure => present,
  }

  file { '/etc/sudoers':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0440',
    source  => 'puppet:///modules/sudoers/sudoers',
    replace => true,
  }
}
