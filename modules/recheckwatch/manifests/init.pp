# == Class: recheckwatch
#
class recheckwatch (
  $gerrit_server = '',
  $gerrit_user = '',
  $recheckwatch_ssh_private_key = '',
) {

  if ! defined(Package['python-daemon']) {
    package { 'python-daemon':
      ensure => present,
    }
  }

  if ! defined(Package['python-genshi']) {
    package { 'python-genshi':
      ensure => present,
    }
  }

  if ! defined(Package['python-launchpadlib']) {
    package { 'python-launchpadlib':
      ensure => present,
    }
  }

  if ! defined(Package['gerritlib']) {
    package { 'gerritlib':
      ensure   => latest,
      provider => pip,
      require  => Class['pip'],
    }
  }

  user { 'recheckwatch':
    ensure     => present,
    home       => '/home/recheckwatch',
    shell      => '/bin/bash',
    gid        => 'recheckwatch',
    managehome => true,
    require    => Group['recheckwatch'],
  }

  group { 'recheckwatch':
    ensure => present,
  }

  file { '/etc/recheckwatch':
    ensure => directory,
  }

  file { '/etc/recheckwatch/recheckwatch.conf':
    ensure  => present,
    owner   => 'recheckwatch',
    mode    => '0400',
    content => template('recheckwatch/recheckwatch.conf.erb'),
    require => [
      File['/etc/recheckwatch'],
      User['recheckwatch'],
    ],
    notify  => Service['recheckwatch'],
  }

  file { '/var/run/recheckwatch':
    ensure  => directory,
    owner   => 'recheckwatch',
    require => User['recheckwatch'],
  }

  file { '/var/www/recheckwatch':
    ensure  => directory,
    owner   => 'recheckwatch',
    mode    => '0755',
    require => User['recheckwatch'],
  }

  file { '/var/lib/recheckwatch':
    ensure  => directory,
    owner   => 'recheckwatch',
    require => User['recheckwatch'],
  }

  file { '/var/lib/recheckwatch/ssh':
    ensure  => directory,
    owner   => 'recheckwatch',
    group   => 'recheckwatch',
    mode    => '0500',
    require => File['/var/lib/recheckwatch'],
  }

  file { '/var/lib/recheckwatch/ssh/id_rsa':
    owner   => 'recheckwatch',
    group   => 'recheckwatch',
    mode    => '0400',
    require => File['/var/lib/recheckwatch/ssh'],
    content => $recheckwatch_ssh_private_key,
  }

  file { '/etc/init.d/recheckwatch':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0555',
    source => 'puppet:///modules/recheckwatch/recheckwatch.init',
  }

  service { 'recheckwatch':
    name       => 'recheckwatch',
    enable     => true,
    hasrestart => true,
    require    => File['/etc/init.d/recheckwatch'],
  }

  file { '/usr/local/bin/recheckwatch':
    ensure  => present,
    mode    => '0555',
    source  => 'puppet:///modules/recheckwatch/recheckwatch',
    notify  => Service['recheckwatch'],
  }
}
