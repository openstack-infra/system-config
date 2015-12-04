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

  file { '/var/log/registry-static':
    ensure => directory,
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
    require => File['/var/log/registry-static']
  }

  class { '::nodejs':
    repo_url_suffix => 'node_0.12',
  }

  # See: https://github.com/davglass/registry-static/pull/45
  package { 'patch-package-json':
    ensure   => '0.0.4',
    provider => 'npm',
    require  => Class['nodejs'],
  }
  package { 'follow-registry':
    ensure   => '2.0.0',
    provider => 'npm',
    require  => Class['nodejs'],
  }

  # The registry mirroring script.
  package { 'registry-static':
    ensure   => '2.0.0',
    provider => 'npm',
    require  => [
      Package['patch-package-json'],
      Package['follow-registry'],
    ]
  }

  file { '/etc/init.d/registry-static':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0755',
    content => template('openstack_project/registry-static.sh.erb'),
    notify  => Service['registry-static'],
    require => Package['registry-static'],
  }

  service { 'registry-static':
    ensure     => running,
    hasrestart => true,
  }
}
