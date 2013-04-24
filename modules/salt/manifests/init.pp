# Class salt
#
class salt (
  $salt_master = $::fqdn
) {

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

    Apt::Ppa['ppa:saltstack/salt'] -> Package['salt-minion']

  }

  package { 'salt-minion':
    ensure  => present
  }

  file { '/etc/salt/minion':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('salt/minion.erb'),
    replace => true,
    require => Package['salt-minion'],
  }

  service { 'salt-minion':
    ensure    => running,
    enable    => true,
    require   => File['/etc/salt/minion'],
    subscribe => [
      Package['salt-minion'],
      File['/etc/salt/minion'],
    ],
  }
}
