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
    require => File['rabbitmq-env.conf'],
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
    source  => [
      'puppet:///modules/devstack_host/rabbitmq-env.conf',
    ],
  }

  exec { 'Set MySQL server root password':
    command     => 'mysqladmin -uroot password secret',
    path        => '/bin:/usr/bin',
    subscribe   => Package['mysql-server'],
    refreshonly => true,
    unless      => 'mysqladmin -uroot -psecret status',
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
