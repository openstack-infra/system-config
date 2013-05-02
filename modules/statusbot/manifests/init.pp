# == Class: statusbot
#
class statusbot(
  $nick = '',
  $password = '',
  $server = '',
  $channels = '',
  $auth_nicks = '',
  $wiki_user = '',
  $wiki_password = '',
  $wiki_url = '',
  $wiki_pageid = '',
) {

  user { 'statusbot':
    ensure     => present,
    home       => '/home/statusbot',
    shell      => '/bin/bash',
    gid        => 'statusbot',
    managehome => true,
    require    => Group['statusbot'],
  }

  group { 'statusbot':
    ensure => present,
  }

  vcsrepo { '/opt/statusbot':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://github.com/openstack-infra/statusbot.git',
  }

  exec { 'install_statusbot' :
    command     => 'python setup.py install',
    cwd         => '/opt/statusbot',
    path        => '/bin:/usr/bin',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/statusbot'],
  }

  file { '/etc/init.d/statusbot':
    ensure  => present,
    group   => 'root',
    mode    => '0555',
    owner   => 'root',
    require => Vcsrepo['/opt/statusbot'],
    source  => 'puppet:///modules/statusbot/statusbot.init',
  }

  service { 'statusbot':
    enable     => true,
    hasrestart => true,
    require    => File['/etc/init.d/statusbot'],
    subscribe  => [
      Vcsrepo['/opt/statusbot'],
      File['/etc/statusbot/statusbot.config'],
    ],
  }

  file { '/etc/statusbot':
    ensure => directory,
  }

  file { '/var/log/statusbot':
    ensure => directory,
    owner  => 'statusbot',
    group  => 'statusbot',
    mode   => '0775',
  }

  file { '/var/run/statusbot':
    ensure => directory,
    owner  => 'statusbot',
    group  => 'statusbot',
    mode   => '0775',
  }

  file { '/etc/statusbot/logging.config':
    ensure  => present,
    group   => 'statusbot',
    mode    => '0440',
    owner   => 'root',
    replace => true,
    require => User['statusbot'],
    source  => 'puppet:///modules/statusbot/logging.config',
  }

  file { '/etc/statusbot/statusbot.config':
    ensure  => present,
    content => template('statusbot/statusbot.config.erb'),
    group   => 'statusbot',
    mode    => '0440',
    owner   => 'root',
    replace => true,
    require => User['statusbot'],
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
