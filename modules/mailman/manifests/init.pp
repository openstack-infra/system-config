class mailman($mailman_host='') {

  package { "mailman":
    ensure => installed,
  }

  package { "apache2":
    ensure => installed,
  }

  file { '/etc/mailman/mm_cfg.py':
    owner => 'root',
    group => 'root',
    mode => 444,
    ensure => 'present',
    content => template('mailman/mm_cfg.py.erb'),
    replace => 'true',
    require => Package["mailman"]
  }

  file { '/etc/mailman/apache.conf':
    owner => 'root',
    group => 'root',
    mode => 444,
    ensure => 'present',
    source => 'puppet:///modules/mailman/apache.conf',
    replace => 'true',
    require => Package["mailman"]
  }

  service { 'mailman':
    ensure          => running,
    hasrestart      => true,
    subscribe       => File['/etc/mailman/mm_cfg.py'],
    require         => Package["mailman"]
  }

  service { 'apache2':
    ensure          => running,
    hasrestart      => true,
    subscribe       => File['/etc/mailman/apache.conf'],
    require         => Package["apache2"]
  }
}
