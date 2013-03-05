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

  group { 'openstackwatch':
    ensure => present,
  }

  user { 'openstackwatch':
    ensure  => present,
    comment => 'OpenStackWatch User',
    shell   => '/bin/bash',
    gid     => 'openstackwatch',
    require => Group['openstackwatch'],
  }

  cron { 'openstackwatch':
    ensure  => present,
    command => "go here $json_url and publish results',
    minute  => $minute,
    hour    => $hour,
    user    => 'openstackwatch'
    require => [
      Class['jeepyb'],
      User['openstackwatch'],
    ],
  }

  file { '/etc/openstackwatch.ini':
    ensure      => present,
    content     => template('openstackwatch.ini.erb'),
    owner       => 'root',
    group       => 'openstackwatch',
    mode        => '0640',
    require     => Group['openstackwatch'],
  }
}
