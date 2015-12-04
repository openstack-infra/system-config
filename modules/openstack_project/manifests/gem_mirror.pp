# == Class: openstack_project::gem_mirror
#
class openstack_project::gem_mirror (
  $data_directory,
  $parallelism    = '10',
  $cron_frequency = '*/5',
) {

  include ::logrotate

  logrotate::file { 'rubygems-mirror':
    log     => '/var/log/rubygems/mirror.log',
    options => [
      'compress',
      'copytruncate',
      'missingok',
      'rotate 7',
      'daily',
      'notifempty',
    ],
  }

  file { $data_directory:
    ensure  => directory,
    owner   => 'rubygems',
    group   => 'root',
    require => User['rubygems'],
  }

  user { 'rubygems':
    ensure     => 'present',
    comment    => 'Service used to run rubygems mirror synchronization',
    managehome => true,
    require    => Package['rubygems-mirror'],
  }

  file { '/home/rubygems/.gem':
    ensure  => directory,
    owner   => 'rubygems',
    group   => 'rubygems',
    mode    => '0600',
    replace => true,
    require => User['rubygems'],
  }

  file { '/home/rubygems/.gem/.mirrorrc':
    ensure  => present,
    owner   => 'rubygems',
    group   => 'rubygems',
    mode    => '0600',
    content => template('openstack_project/rubygems_mirrorrc.erb'),
    replace => true,
    require => File['/home/rubygems/.gem'],
  }

  package { 'rubygems-mirror':
    ensure   => latest,
    provider => gem,
  }

  file { ['/var/run/rubygems','/var/log/rubygems']:
    ensure  => directory,
    owner   => 'rubygems',
    group   => 'root',
    require => User['rubygems'],
  }

  cron { 'rubygems-mirror':
    minute      => $cron_frequency,
    command     => 'flock -n /var/run/rubygems/mirror.lock timeout -k 2m 30m gem mirror >>/var/log/rubygems/mirror.log 2>&1',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    user        => 'rubygems',
    require     => [
      File['/home/rubygems/.gem/.mirrorrc'],
      User['rubygems'],
      Package['rubygems-mirror'],
    ]
  }

}
