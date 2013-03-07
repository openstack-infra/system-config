# == Class: pypimorror
#
class pypimirror(
  $vhost_name = $::fqdn,
  $mirror_config = '',
  $mirror_root = '/var/lib/pypimirror',
) {

  include apache
  include pip
  include jeepyb

  $log_root = '/var/log/pypimirror/'
  $log_filename = "${log_root}/pypimirror.log"
  $cache_root = '/var/cache/pypimirror'

  if ! defined(Package['python-yaml']) {
    package { 'python-yaml':
      ensure => present,
    }
  }

  user { 'mirror':
    ensure     => present,
    home       => '/home/mirror',
    shell      => '/bin/bash',
    gid        => 'mirror',
    managehome => true,
    require    => Group['mirror'],
  }

  group { 'mirror':
    ensure => present,
  }

  file { $log_root:
    ensure  => directory,
    mode    => '0755',
    owner   => 'mirror',
    group   => 'mirror',
    require => User['mirror'],
  }

  file { $cache_root:
    ensure  => directory,
    mode    => '0755',
    owner   => 'mirror',
    group   => 'mirror',
    require => User['mirror'],
  }

  file { $mirror_root:
    ensure  => directory,
    mode    => '0755',
    owner   => 'mirror',
    group   => 'mirror',
    require => User['mirror'],
  }

  file { '/usr/local/bin/run-mirror.sh':
    ensure  => present,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    content => template('pypimirror/run-mirror.sh.erb'),
  }

  # Add cron job to update the mirror

  cron { 'update_mirror':
    ensure  => absent,
    user    => 'root',
    hour    => '0',
    command => '/usr/local/bin/run-mirror.sh',
    require => File['/usr/local/mirror_scripts/run-mirror.sh'],
  }

  cron { 'update_pypi_mirror':
    user    => 'mirror',
    hour    => '0',
    command => '/usr/local/bin/run-mirror.sh',
    require => File['/usr/local/bin/run-mirror.sh'],
  }

  # Rotate the mirror log file

  include logrotate
  logrotate::file { 'pypimirror':
    log     => $log_filename,
    options => [
      'compress',
      'delaycompress',
      'missingok',
      'rotate 7',
      'daily',
      'notifempty',
    ],
    require => Cron['update_mirror'],
  }

  apache::vhost { $vhost_name:
    port     => 80,
    docroot  => $mirror_root,
    priority => 50,
  }
}
