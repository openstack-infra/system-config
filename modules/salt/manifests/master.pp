# Class salt::master
#
class salt::master {

  if ($::osfamily == 'Debian') {
    include apt

    # Wrap in ! defined checks to allow minion and master installs on the
    # same host.
    if ! defined(Apt::Ppa['ppa:saltstack/salt']) {
      apt::ppa { 'ppa:saltstack/salt': }
    }

    if ! defined(Package['python-software-properties']) {
      package { 'python-software-properties':
        ensure => present,
      }
    }

    Apt::Ppa['ppa:saltstack/salt'] -> Package['salt-master']

  }

  package { 'salt-master':
    ensure  => present
  }

  group { 'salt':
    ensure => present,
    system => true,
  }

  user { 'salt':
    ensure  => present,
    gid     => 'salt',
    home    => '/home/salt',
    shell   => '/bin/bash',
    system  => true,
    require => Group['salt'],
  }

  file { '/home/salt':
    ensure  => directory,
    owner   => 'salt',
    group   => 'salt',
    mode    => '0755',
    require => User['salt'],
  }

  file { '/etc/salt/master':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('salt/master.erb'),
    replace => true,
    require => Package['salt-master'],
  }

  file { '/etc/salt/pki':
    ensure  => directory,
    owner   => 'salt',
    group   => 'salt',
    mode    => '0710',
    require => [
      Package['salt-master'],
      User['salt'],
    ],
  }

  file { '/etc/salt/pki/master':
    ensure  => directory,
    owner   => 'salt',
    group   => 'salt',
    mode    => '0770',
    require => File['/etc/salt/pki'],
  }

  file { '/etc/salt/pki/master/minions':
    ensure  => directory,
    owner   => 'salt',
    group   => 'salt',
    mode    => '0775',
    require => File['/etc/salt/pki/master'],
  }

  service { 'salt-master':
    ensure    => stopped,
    enable    => false,
    require   => [
      User['salt'],
      File['/etc/salt/master'],
    ],
    subscribe => [
      Package['salt-master'],
      File['/etc/salt/master'],
    ],
  }
}
