# == Class: openstack_project::pypi_mirror
#
class openstack_project::pypi_mirror (
  $data_directory = '/srv/static/mirror',
  $cron_frequency = '*/5',
) {

  file { "${data_directory}":
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
  }

  file { "${data_directory}/web":
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    require => File["${data_directory}"],
  }

  package { 'bandersnatch':
    ensure   => 'latest',
    provider => 'pip',
  }

  file { '/etc/bandersnatch.conf':
    ensure  => present,
    content => template('openstack_project/bandersnatch.conf.erb'),
  }

  file { '/var/log/bandersnatch':
    ensure => directory,
  }

  file { '/var/run/bandersnatch':
    ensure => directory,
  }

  cron { 'bandersnatch':
    minute      => $cron_frequency,
    command     => 'flock -n /var/run/bandersnatch/mirror.lock timeout -k 2m 30m run-bandersnatch >>/var/log/bandersnatch/mirror.log 2>&1',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
  }

  include logrotate
  logrotate::file { 'bandersnatch':
    log     => '/var/log/bandersnatch/mirror.log',
    options => [
      'compress',
      'copytruncate',
      'missingok',
      'rotate 7',
      'daily',
      'notifempty',
    ],
  }

  file { '/usr/local/bin/run-bandersnatch':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/openstack_project/run_bandersnatch.py',
  }
}
