# Class salt::master
#
class salt::master (
  $ensure = present,
) {

  if ($ensure == present) {
    $directory_ensure = directory
    $running_ensure = running
  } else {
    $directory_ensure = absent
    $running_ensure = stopped
  }

  if ($::osfamily == 'Debian') {
    include apt

    # Wrap in ! defined checks to allow minion and master installs on the
    # same host.
    if ! defined(Apt::Ppa['ppa:saltstack/salt']) {
      apt::ppa { 'ppa:saltstack/salt':
        ensure => $ensure
      }
    }

    if ! defined(Package['python-software-properties']) {
      package { 'python-software-properties':
        ensure => $ensure,
      }
    }

    Apt::Ppa['ppa:saltstack/salt'] -> Package['salt-master']

  }

  package { 'salt-master':
    ensure  => $ensure
  }

  group { 'salt':
    ensure => $ensure,
    system => true,
  }

  user { 'salt':
    ensure  => $ensure,
    gid     => 'salt',
    home    => '/home/salt',
    shell   => '/bin/bash',
    system  => true,
    require => Group['salt'],
  }

  file { '/home/salt':
    ensure  => $directory_ensure,
    owner   => 'salt',
    group   => 'salt',
    mode    => '0755',
    require => User['salt'],
  }

  file { '/etc/salt/master':
    ensure  => $ensure,
    owner   => 'salt',
    group   => 'salt',
    mode    => '0644',
    content => template('salt/master.erb'),
    replace => true,
    require => Package['salt-master'],
  }

  file { '/srv/reactor':
    ensure  => $directory_ensure,
    owner   => 'salt',
    group   => 'salt',
    mode    => '0755',
    require => [
      Package['salt-master'],
      User['salt'],
    ],
  }

  file { '/srv/reactor/tests.sls':
    ensure  => $ensure,
    owner   => 'salt',
    group   => 'salt',
    mode    => '0644',
    content => template('salt/tests.reactor.erb'),
    replace => true,
    require => [
      Package['salt-master'],
      File['/srv/reactor'],
    ],
  }

  file { '/etc/salt/pki':
    ensure  => $directory_ensure,
    owner   => 'salt',
    group   => 'salt',
    mode    => '0710',
    require => [
      Package['salt-master'],
      User['salt'],
    ],
  }

  file { '/etc/salt/pki/master':
    ensure  => $directory_ensure,
    owner   => 'salt',
    group   => 'salt',
    mode    => '0770',
    require => File['/etc/salt/pki'],
  }

  file { '/etc/salt/pki/master/minions':
    ensure  => $directory_ensure,
    owner   => 'salt',
    group   => 'salt',
    mode    => '0775',
    require => File['/etc/salt/pki/master'],
  }

  service { 'salt-master':
    ensure    => $running_ensure,
    enable    => true,
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
