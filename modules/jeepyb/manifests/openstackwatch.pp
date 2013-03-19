# == Class: jeepyb::openstackwatch

class jeepyb::openstackwatch(
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

  group { 'openstackwatch':
    ensure => present,
  }

  user { 'openstackwatch':
    ensure     => present,
    managehome => true,
    comment    => 'OpenStackWatch User',
    shell      => '/bin/bash',
    gid        => 'openstackwatch',
    require    => Group['openstackwatch'],
  }

  if $swift_password != '' {
    cron { 'openstackwatch':
      ensure  => present,
      command => '/usr/local/bin/openstackwatch /home/openstackwatch/openstackwatch.ini',
      minute  => $minute,
      hour    => $hour,
      user    => 'openstackwatch',
      require => [
        File['/home/openstackwatch/openstackwatch.ini'],
        User['openstackwatch'],
        Class['jeepyb'],
      ],
    }
  }

  file { '/home/openstackwatch/openstackwatch.ini':
    ensure  => present,
    content => template('jeepyb/openstackwatch.ini.erb'),
    owner   => 'root',
    group   => 'openstackwatch',
    mode    => '0640',
    require => User['openstackwatch'],
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
