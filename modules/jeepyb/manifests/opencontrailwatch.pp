# == Class: jeepyb::opencontrailwatch

class jeepyb::opencontrailwatch(
  $swift_username = '',
  $swift_password = '',
  $swift_auth_url = '',
  $auth_version = '',
  $projects = [],
  $mode = 'multiple',
  $container = 'rss',
  $feed = '',
  $json_url = '',
  $minute = '18',
  $hour = '*',
) {
  include jeepyb

  group { 'opencontrailwatch':
    ensure => present,
  }

  user { 'opencontrailwatch':
    ensure     => present,
    managehome => true,
    comment    => 'OpenContrailWatch User',
    shell      => '/bin/bash',
    gid        => 'opencontrailwatch',
    require    => Group['opencontrailwatch'],
  }

  if $swift_password != '' {
    cron { 'opencontrailwatch':
      ensure  => present,
      command => '/usr/local/bin/opencontrailwatch /home/opencontrailwatch/opencontrailwatch.ini',
      minute  => $minute,
      hour    => $hour,
      user    => 'opencontrailwatch',
      require => [
        File['/home/opencontrailwatch/opencontrailwatch.ini'],
        User['opencontrailwatch'],
        Class['jeepyb'],
      ],
    }
  }

  file { '/home/opencontrailwatch/opencontrailwatch.ini':
    ensure  => present,
    content => template('jeepyb/opencontrailwatch.ini.erb'),
    owner   => 'root',
    group   => 'opencontrailwatch',
    mode    => '0640',
    require => User['opencontrailwatch'],
  }

  if ! defined(Package['python-pyrss2gen']) {
    package { 'python-pyrss2gen':
      ensure => present,
    }
  }

  if ! defined(Package['python-swiftclient']) {
    package { 'python-swiftclient':
      ensure   => latest,
      provider => pip,
      require  => Class['pip'],
    }
  }
}
