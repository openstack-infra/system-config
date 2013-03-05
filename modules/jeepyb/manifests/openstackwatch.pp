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

  cron { 'openstackwatch':
    ensure  => present,
    command => "go here $json_url and publish results',
    minute  => $minute,
    hour    => $hour,
  }

  file { '/etc/openstackwatch.ini':
    ensure      => present,
    content     => template('openstackwatch.ini.erb'),
    owner       => 'root',
    group       => 'root',
    mode        => '0640',
  }
}
