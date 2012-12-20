# == Class: Askbot
#
# Class to install askbot.
#

class askbot {
  include apache
  a2mod { 'rewrite':
    ensure => present,
  }
  a2mod { 'proxy':
    ensure => present,
  }
  a2mod { 'proxy_http':
    ensure => present,
  }
  include apache::mod::wsgi
  include pip

  # Create askbot user and dirs.
  file { '/opt/askbot':
    ensure => directory,
    owner  => 'askbot',
    group  => 'www-data',
    mode   => '0640',
  }

  user { 'askbot':
    ensure     => present,
    home       => '/opt/askbot',
    shell      => '/bin/bash',
    gid        => 'askbot',
    managehome => false,
    require    => Group['askbot'],
  }

  group { 'askbot':
    ensure => present,
  }

  package { 'python-memcached':
    ensure   => present,
    provider => 'pip',
  }

  class { 'memcached':
    listen_ip => '127.0.0.1',
    require   => Package['python-memcached'],
  }

  # Install askbot
  vcsrepo { '/opt/askbot/askbot-devel':
    ensure   => present,
    provider => git,
    source   => 'git://github.com/emonty/askbot-devel.git',
    revision => 'master',
    require  => [
        Package['git'],
        File['/opt/askbot'],
        Class['memcached'],
    ],
  }

  exec { 'install_askbot' :
    command     => 'python setup.py develop',
    cwd         => '/opt/askbot/askbot-devel',
    path        => '/bin:/usr/bin',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/askbot/askbot-devel'],
  }
}
