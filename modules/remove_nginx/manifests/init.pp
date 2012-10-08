class remove_nginx {
  package { 'nginx':
    ensure => absent,
  }
  file { '/etc/nginx/sites-available/default':
    ensure => absent,
  }
  service { 'nginx':
    ensure => stopped,
  }
}
