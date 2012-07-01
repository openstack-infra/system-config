class ulimit {

  package { ['libpam-modules', 'libpam-modules-bin']:
    ensure => present
  }

  file { '/etc/security/limits.d':
    ensure => directory,
    owner  => 'root',
    mode   => 0755
  }

}
