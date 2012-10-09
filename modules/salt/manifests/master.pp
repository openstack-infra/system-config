class salt (
  $master = $::fqdn
) {
  class { 'salt':
    master => $master
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
}
