class exim(
  $mailman_domains = [],
  $sysadmin = []
) {
  package { 'exim4-base':
    ensure => present,
  }

  package { 'exim4-config':
    ensure => present,
  }

  package { 'exim4-daemon-light':
    ensure  => present,
    require => [
      Package[exim4-base],
      Package[exim4-config]
    ],
  }

  service { 'exim4':
    ensure      => running,
    hasrestart  => true,
    subscribe   => File['/etc/exim4/exim4.conf'],
  }

  file { '/etc/exim4/exim4.conf':
    ensure  => present,
    content => template('exim/exim4.conf.erb'),
    group   => 'root',
    mode    => '0444',
    owner   => 'root',
    replace => true,
  }

  file { '/etc/aliases':
    ensure  => present,
    content => template('exim/aliases.erb'),
    group   => 'root',
    mode    => '0444',
    owner   => 'root',
    replace => true,
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
