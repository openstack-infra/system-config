class unattended_upgrades($ensure = present) {
  package { 'unattended-upgrades':
    ensure => $ensure;
  }

  package { 'mailutils':
    ensure => $ensure;
  }

  file { '/etc/apt/apt.conf.d/10periodic':
    owner => 'root',
    group => 'root',
    mode => 444,
    ensure => $ensure,
    source => "puppet:///modules/unattended_upgrades/10periodic",
    replace => 'true',
  }

  file { '/etc/apt/apt.conf.d/50unattended-upgrades':
    owner => 'root',
    group => 'root',
    mode => 444,
    ensure => $ensure,
    source => "puppet:///modules/unattended_upgrades/50unattended-upgrades",
    replace => 'true',
  }

}
