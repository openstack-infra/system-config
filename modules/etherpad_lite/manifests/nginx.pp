class etherpad_lite::nginx (
  $default_server = 'default_server',
  $server_name    = $fqdn,
  $etherpad_crt,
  $etherpad_key
) {

  package { 'nginx':
    ensure => present
  }

  file { '/etc/nginx/sites-enabled/default':
    ensure  => absent,
    require => Package['nginx'],
    notify  => Service['nginx']
  }

  file { '/etc/nginx/sites-available/etherpad-lite':
    ensure  => present,
    content => template('etherpad_lite/nginx.erb'),
    replace => 'true',
    owner   => 'root',
    require => File['/etc/nginx/ssl/eplite.crt', '/etc/nginx/ssl/eplite.key'],
    notify  => Service['nginx']
  }

  file { '/etc/nginx/sites-enabled/etherpad-lite':
    ensure => link,
    target => '/etc/nginx/sites-available/etherpad-lite'
  }

  file { '/etc/nginx/ssl':
    ensure => directory,
    owner  => 'root',
    mode   => 0700,
  }

  file { '/etc/nginx/ssl/eplite.crt':
    ensure  => present,
    replace => true,
    owner   => 'root',
    mode    => 0600,
    content => template('etherpad_lite/eplite.crt.erb'),
    require => Package['nginx'],
  }

  file { '/etc/nginx/ssl/eplite.key':
    ensure  => present,
    replace => true,
    owner   => 'root',
    mode    => 0600,
    content => template('etherpad_lite/eplite.key.erb'),
    require => Package['nginx'],
  }

  service { 'nginx':
    enable     => true,
    ensure     => running,
    hasrestart => true
  }

}
