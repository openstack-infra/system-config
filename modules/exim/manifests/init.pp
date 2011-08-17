class exim() {
  package {
    'exim4-daemon-light': ensure => present;
  }

  service { 'exim4':
    ensure          => running,
    hasrestart      => true,
    subscribe       => File['/etc/exim4/exim4.conf'],
  }

  file { '/etc/exim4/exim4.conf':
    owner => 'root',
    group => 'root',
    mode => 444,
    ensure => 'present',
    source => 'puppet:///modules/exim/exim4.conf',
    replace => 'true',
  }

  file { '/etc/aliases':
    owner => 'root',
    group => 'root',
    mode => 444,
    ensure => 'present',
    source => 'puppet:///modules/exim/aliases',
    replace => 'true',
  }
}
