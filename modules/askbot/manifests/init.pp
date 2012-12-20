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
  include pip

  # Create askbot user and dirs.
  file { '/opt/askbot':
    ensure => directory,
    owner   => 'askbot',
    mode    => '0640',
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

  # Install askbot
  vcsrepo { '/opt/askbot/askbot-devel':
    ensure   => present,
    provider => git,
    source   => 'git://github.com/ASKBOT/askbot-devel.git',
    revision => '0.7.47',
    require  => [
        Package['git'],
        File['/opt/askbot'],
    ],
  }

  exec { 'install_askbot' :
    command     => 'python setup.py develop',
    cwd         => '/opt/askbot/askbot-devel',
    path        => '/bin:/usr/bin',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/askbot/askbot-devel'],
  }

  # Install MySQL.
  include mysql::python

  class { 'mysql::server':
    config_hash => {
      'root_password'  => $mysql_root_password,
      'default_engine' => 'InnoDB',
      'bind_address'   => '127.0.0.1',
    }
  }
  include mysql::server::account_security
}
