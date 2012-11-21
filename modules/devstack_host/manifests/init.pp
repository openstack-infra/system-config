# == Class: devstack_host
#
# A machine ready to run devstack
class devstack_host {
  package { 'linux-headers-virtual':
    ensure => present,
  }

  package { 'mysql-server':
    ensure => present,
  }

  package { 'rabbitmq-server':
    ensure  => present,
    require => File['/etc/rabbitmq/rabbitmq-env.conf'],
  }

  file { '/etc/rabbitmq':
    ensure => directory,
  }

  file { '/etc/rabbitmq/rabbitmq-env.conf':
    ensure  => present,
    group   => 'root',
    mode    => '0444',
    owner   => 'root',
    require => File['/etc/rabbitmq'],
    source  => 'puppet:///modules/devstack_host/rabbitmq-env.conf',
  }

  # TODO: We should be using existing mysql functions do this.
  exec { 'Set MySQL server root password':
    command     => 'mysqladmin -uroot password secret',
    path        => '/bin:/usr/bin',
    refreshonly => true,
    subscribe   => Package['mysql-server'],
    unless      => 'mysqladmin -uroot -psecret status',
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
