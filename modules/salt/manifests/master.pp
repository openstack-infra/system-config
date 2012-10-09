class salt::master {
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

  package { 'salt-master':
    ensure  => present,
    require => Apt::Ppa['ppa:saltstack/salt'],
  }

  file { '/etc/salt/master':
    ensure => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('salt/master.erb'),
    replace => true,
    require => Package['salt-master'],
  }

  service { 'salt-master':
    ensure    => running,
    enable    => true,
    require   => File['/etc/salt/master'],
    subscribe => [
      Package['salt-master'],
      File['/etc/salt/master'],
    ],
  }
}
