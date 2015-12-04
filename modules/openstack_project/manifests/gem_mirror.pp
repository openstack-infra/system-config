# == Class: openstack_project::gem_mirror
#
class openstack_project::gem_mirror (
  $data_directory = '/afs/.openstack.org/mirror/gem',
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
    group   => 'rubygems',
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
    require => File['/rooy/.gem'],
  }

  package { 'rubygems-mirror':
    ensure   => latest,
    provider => gem,
  }

  file { ['/var/run/rubygems','/var/log/rubygems']:
    ensure  => directory,
    owner   => 'rubygems',
    group   => 'rubygems',
    require => User['rubygems'],
  }
}
