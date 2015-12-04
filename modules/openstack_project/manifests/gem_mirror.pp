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
    owner   => 'root',
    group   => 'root',
  }

  file { '/root/.gem':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    replace => true,
  }

  file { '/root/.gem/.mirrorrc':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
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
    owner   => 'root',
    group   => 'root',
  }


}
