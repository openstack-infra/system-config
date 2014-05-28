# Class salt
#
class salt (
  $ensure = present,
  $salt_master = $::fqdn
) {

  if ($ensure == present) {
    $running_ensure = running
  } else {
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

    Apt::Ppa['ppa:saltstack/salt'] -> Package['salt-minion']

  }

  package { 'salt-minion':
    ensure  => $ensure
  }

  file { '/etc/salt/minion':
    ensure  => $ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('salt/minion.erb'),
    replace => true,
    require => Package['salt-minion'],
  }

  service { 'salt-minion':
    ensure    => $running_ensure,
    enable    => true,
    require   => File['/etc/salt/minion'],
    subscribe => [
      Package['salt-minion'],
      File['/etc/salt/minion'],
    ],
  }
}
