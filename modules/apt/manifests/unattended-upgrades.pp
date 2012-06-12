class apt::unattended-upgrades($email='') {
  package { 'unattended-upgrades':
    ensure => present;
  }

  package { 'mailutils':
    ensure => present;
  }

  file { '/etc/apt/apt.conf.d/10periodic':
    owner => 'root',
    group => 'root',
    mode => 444,
    ensure => 'present',
    source => "puppet:///modules/apt/10periodic",
    replace => 'true',
  }

  file { '/etc/apt/apt.conf.d/50unattended-upgrades':
    owner => 'root',
    group => 'root',
    mode => 444,
    ensure => 'present',
    source => "puppet:///modules/apt/50unattended-upgrades",
    replace => 'true',
  }
  
}
