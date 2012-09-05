class tmpreaper() {
  package { 'tmpreaper':
    ensure => present,
  }

  file { '/etc/cron.daily/tmpreaper':
    ensure => absent
  }

  file { '/usr/local/bin/tmpreaper.sh':
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => 755,
    source => 'puppet:///modules/tmpreaper/tmpreaper.sh',
  }

  file { '/etc/tmpreaper.conf':
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => 644,
    source => 'puppet:///modules/tmpreaper/tmpreaper.conf',
  }

  cron { 'tmpreaper':
    user    => 'root',
    minute  => '42',
    hour    => '*/6',
    command => 'sleep $((RANDOM\%60+60)) && /usr/local/bin/tmpreaper.sh',
    require => File['/usr/local/bin/tmpreaper.sh'],
  }
}
