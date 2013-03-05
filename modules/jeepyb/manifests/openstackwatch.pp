class jeepyb::openstackwatch(
  $projects = [],
  $container = 'rss',
  $feed = '',
) {
  include jeepyb

  cron { 'openstackwatch':
    ensure  => present,
    command => "go here $json_url and publish results',
    minute  => $minute,
    hour    => $hour,
  }

  file { '/etc/openstackwatch.ini':
    ensure      => present,
    content     => template('openstackwatch.ini.erb'),
    projects    => $projects,
    container   => $container,
    feed        => $feed,
    owner       => 'root',
    group       => 'root',
    mode        => '0640',
  }
}
