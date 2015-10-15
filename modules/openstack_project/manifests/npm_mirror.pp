# == Class: openstack_project::npm_mirror
#
class openstack_project::npm_mirror (
  $uri_rewrite,
  $data_directory,
) {

  include ::logrotate

  file { $data_directory:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    before  => Service['registry-static'],
  }

  logrotate::file { 'registry-static':
    log     => '/var/log/registry-static/mirror.log',
    options => [
      'daily',
      'missingok',
      'rotate 7',
      'compress',
      'delaycompress',
      'notifempty',
    ],
  }

  class { '::nodejs':
    repo_url_suffix => 'node_0.12',
  }

  package { 'registry-static':
    ensure   => '2.0.0',
    provider => 'npm',
    require  => Class['nodejs'],
  }

  file { '/etc/init.d/registry-static':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0755',
    content => template('openstack_project/registry-static.sh.erb'),
    notify  => Service['registry-static'],
    before  => Service['registry-static'],
    require => Package['registry-static'],
  }

  service { 'registry-static':
    ensure     => running,
    hasrestart => true,
  }
}