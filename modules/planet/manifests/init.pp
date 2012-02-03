class planet {

  package { 'planet-venus':
    ensure => present
  }

  package { 'nginx':
    ensure => present
  }

  file { '/srv/planet':
    ensure => directory
  }

  file { '/var/lib/planet':
    ensure => directory
  }

  service { 'nginx':
    ensure => running,
    hasrestart => true
  }

}
