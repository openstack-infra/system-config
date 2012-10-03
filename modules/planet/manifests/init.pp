class planet {
  package { 'planet-venus':
    ensure => present,
  }

  file { '/srv/planet':
    ensure => directory,
  }

  file { '/var/lib/planet':
    ensure => directory,
  }

  file { '/var/log/planet':
    ensure => directory,
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
