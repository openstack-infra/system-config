# == Class: openstack_project::rubygems_mirror
#
class openstack_project::rubygems_mirror (
  $vhost_name,
  $parallelism      = '10',
  $destination_path = '/srv/static/mirror/rubygems',
  $cron_frequency   = '*/5',
) {

  include ::apache

  if ! defined(File['/srv/static']) {
    ensure_resource('file', '/srv/static', {
      'ensure' => 'directory',
    })
  }

  ensure_resource('file', '/srv/static/mirror', {
    'ensure'  => 'directory',
    'owner'   => 'root',
    'group'   => 'root',
  })

  file { '/srv/static/mirror/rubygems':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    require => File['/srv/static/mirror'],
  }

  # need to figure out how to deal with pypi vhost.
  # we should probably create rubygems.openstack.org ?
  apache::vhost { $vhost_name:
    port     => 80,
    priority => '50',
    docroot  => $destination_path,
    require  => File[$destination_path],
  }

  file { '/home/gerrit2/.gems/.mirrorrc':
    ensure  => present,
    owner   => 'gerrit2',
    group   => 'gerrit2',
    mode    => '0600',
    content => template('openstack_project/rubygems_mirrorrc.erb'),
    replace => true,
  }

  file { '/srv/static/mirror/rubygems/robots.txt':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    source  => 'puppet:///modules/openstack_project/disallow_robots.txt',
    require => File['/srv/static/mirror/web'],
  }

  package { 'rubygems-mirror':
    ensure   => latest,
    provider => gem,
  }

  file { '/var/log/rubygems':
    ensure => directory,
  }

  cron { 'rubygems-mirror':
    minute      => $cron_frequency,
    command     => 'gem mirror >>/var/log/rubygems-mirror/mirror.log 2>&1',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    user        => 'gerrit2',
  }

  include ::logrotate
  logrotate::file { 'rubygems-mirror':
    log     => '/var/log/rubygems-mirror/mirror.log',
    options => [
      'compress',
      'copytruncate',
      'missingok',
      'rotate 7',
      'daily',
      'notifempty',
    ],
  }

}
