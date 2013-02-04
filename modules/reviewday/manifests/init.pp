class reviewday {
  package { [
      'python-cheetah',
      'python-launchpadlib',
    ]:
    ensure => present,
  }

  file { '/srv/reviewday':
    ensure => directory,
  }

  file { '/var/lib/planet':
    ensure => directory,
  }

}

# vim:sw=2:ts=2:expandtab:textwidth=79
