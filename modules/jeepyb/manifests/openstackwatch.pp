# == Class: jeepyb::openstackwatch

class jeepyb::openstackwatch(
  $projects = [],
  $mode = 'multiple',
  $container = 'rss',
  $feed = '',
  $json_url = '',
  $minute = '18',
  $hour = '*',
) {
  include jeepyb

  user { 'openstackwatch':
    ensure  => present,
    comment => 'OpenStackWatch User',
    shell   => '/bin/bash',
    gid     => 'openstackwatch',
  }

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

  file { '/home/openstackwatch/openstackwatch.ini':
    ensure  => present,
    content => template('jeepyb/openstackwatch.ini.erb'),
    owner   => 'root',
    group   => 'openstackwatch',
    mode    => '0640',
  }
}
