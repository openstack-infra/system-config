class etherpad_lite::nginx (
  $default_server = 'default_server',
  $server_name    = 'localhost'
) {

  package { 'nginx':
    ensure => present
  }

  file { '/etc/nginx/sites-enabled/default':
    ensure  => absent,
    require => Package['nginx'],
    notify  => Service['nginx']
  }

  file { '/etc/nginx/sites-enabled/etherpad-lite':
    ensure  => present,
    content => template('etherpad_lite/nginx.erb'),
    replace => 'true',
    owner   => 'root',
    require => Package['nginx'],
    notify  => Service['nginx']
  }

  service { 'nginx':
    enable     => true,
    ensure     => running,
    hasrestart => true
  }

}
