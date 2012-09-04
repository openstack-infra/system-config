class tmpreaper() {
  package { 'tmpreaper':
    ensure => present,
  }

  file { '/etc/tmpreaper':
    name   => '/etc/tmpreaper',
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => 755
  }

  file { 'tmpreaper.sh':
    name   => '/etc/tmpreaper/tmpreaper.sh',
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => 755,
    source => 'puppet:///modules/tmpreaper/tmpreaper.sh',
  }

  file { 'tmpreaper.conf':
    name   => '/etc/tmpreaper.conf',
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => 644,
    source => 'puppet:///modules/tmpreaper/tmpreaper.conf',
  }

  cron { "sync_launchpad_users":
    user    => root,
    minute  => '42',
    hour    => '*/6',
    command => 'sleep $((RANDOM\\%60+60)) && /etc/tmpreaper/tmpreaper.sh',
    require => File['/etc/tmpreaper/tmpreaper.sh'],
  }
}
