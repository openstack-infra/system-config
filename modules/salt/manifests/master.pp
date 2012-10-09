class salt (
  $salt_master = $::fqdn
) {
  class { 'salt':
    salt_master => $salt_master
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
