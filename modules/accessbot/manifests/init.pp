# == Class: accessbot
#
class accessbot(
  $nick = '',
  $password = '',
  $server = '',
  $channel_file = '',
) {

  user { 'accessbot':
    ensure     => present,
    home       => '/home/accessbot',
    shell      => '/bin/bash',
    gid        => 'accessbot',
    managehome => true,
    require    => Group['accessbot'],
  }

  group { 'accessbot':
    ensure => present,
  }

  exec { 'run_accessbot' :
    command     => '/usr/local/bin/accessbot -c /etc/accessbot/accessbot.config -l /etc/accessbot/channels.yaml >> /var/log/accessbot/accessbot.log 2>&1',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
    subscribe   => File['/etc/accessbot/channels.yaml'],
    require     => [File['/etc/accessbot/channels.yaml'],
                    File['/etc/accessbot/accessbot.config'],
                    File['/usr/local/bin/accessbot']],
  }

  file { '/etc/accessbot':
    ensure => directory,
  }

  file { '/var/log/accessbot':
    ensure  => directory,
    owner   => 'accessbot',
    group   => 'accessbot',
    mode    => '0775',
    require => User['accessbot'],
  }

  file { '/etc/accessbot/accessbot.config':
    ensure  => present,
    content => template('accessbot/accessbot.config.erb'),
    group   => 'accessbot',
    mode    => '0440',
    owner   => 'root',
    replace => true,
    require => User['accessbot'],
  }

  file { '/etc/accessbot/channels.yaml':
    ensure  => present,
    source  => $channel_file,
    group   => 'accessbot',
    mode    => '0440',
    owner   => 'root',
    replace => true,
    require => User['accessbot'],
  }

  file { '/usr/local/bin/accessbot':
    ensure  => present,
    source  => 'puppet:///modules/accessbot/accessbot.py',
    group   => 'accessbot',
    mode    => '0440',
    owner   => 'root',
    replace => true,
    require => User['accessbot'],
  }
}
