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
    command => '/usr/local/bin/openstackwatch /etc/openstackwatch.ini',
    minute  => $minute,
    hour    => $hour,
    user    => 'openstackwatch',
    require => [
      File['/etc/openstackwatch.ini'],
      User['openstackwatch'],
    ],
  }

  file { '/etc/openstackwatch.ini':
    ensure  => present,
    content => template('openstackwatch.ini.erb'),
    owner   => 'root',
    group   => 'openstackwatch',
    mode    => '0640',
  }
}
