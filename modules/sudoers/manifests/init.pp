class sudoers {
  group { 'sudo':
    ensure => 'present'
  }
  group { 'admin':
    ensure => 'present'
  }

  file { '/etc/sudoers':
    owner => 'root',
    group => 'root',
    mode => 440,
    ensure => 'present',
    source => "puppet:///modules/sudoers/sudoers",
    replace => 'true',
  }
}
