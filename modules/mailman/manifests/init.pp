class mailman($mailman_host='') {

  package { "mailman":
    ensure => installed,
  }

  package { "apache2":
    ensure => installed,
  }

  file { "/var/www/index.html":
    source => 'puppet:///modules/mailman/index.html',
    owner => 'root',
    group => 'root',
    ensure => 'present',
    replace => 'true',
    mode => 444,
    require => Package["apache2"],
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

  file { "/etc/apache2/sites-available/mailman":
    content => template('mailman/mailman.vhost.erb'),
    owner => 'root',
    group => 'root',
    ensure => 'present',
    replace => 'true',
    mode => 444,
    require => Package["apache2"],
  }

  file { "/etc/apache2/sites-enabled/mailman":
    ensure => link,
    target => '/etc/apache2/sites-available/mailman',
    require => [
      File['/etc/apache2/sites-available/mailman'],
    ],
  }

  file { '/etc/apache2/sites-enabled/000-default':
    require => File['/etc/apache2/sites-available/mailman'],
    ensure => absent,
  }

  exec { "gracefully restart apache":
    subscribe => [ File["/etc/apache2/sites-available/mailman"]],
    refreshonly => true,
    path => "/bin:/usr/bin:/usr/sbin",
    command => "apache2ctl graceful",
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
    subscribe       => File["/etc/apache2/sites-available/mailman"],
    require         => Package["apache2"]
  }

  file { '/etc/mailman/en':
    owner => 'root',
    group => 'list',
    mode => 644,
    ensure => 'directory',
    recurse => true,
    require => Package['mailman'],
    source => [
                "puppet://modules/mailman/html-templates-en",
              ],
  }
}
