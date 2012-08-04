class etherpad_lite::apache (
  $vhost_name = $fqdn,
  $etherpad_crt,
  $etherpad_key
) {

  include remove_nginx

  apache::vhost { $vhost_name:
    post => 443,
    docroot => 'MEANINGLESS ARGUMENT',
    priority => '50',
    template => 'etherpadlite/etherpadlite.vhost.erb',
    require => File["/etc/ssl/certs/${vhost_name}.pem",
                    "/etc/ssl/private/${vhost_name}.key"],
    ssl => true,
  }
  a2mod { 'rewrite':
    ensure => present
  }
  a2mod { 'proxy':
    ensure => present
  }
  a2mod { 'proxy_http':
    ensure => present
  }

  file { '/etc/ssl/certs':
    ensure => directory,
    owner  => 'root',
    mode   => 0700,
  }

  file { '/etc/ssl/private':
    ensure => directory,
    owner  => 'root',
    mode   => 0700,
  }

  file { "/etc/ssl/cert/${vhost_name}.pem":
    ensure  => present,
    replace => true,
    owner   => 'root',
    mode    => 0600,
    content => template('etherpad_lite/eplite.crt.erb'),
    require => Apache::Vhost[$vhost_name],
  }

  file { '/etc/ssl/private/${vhost_name}.key':
    ensure  => present,
    replace => true,
    owner   => 'root',
    mode    => 0600,
    content => template('etherpad_lite/eplite.key.erb'),
    require => Apache::Vhost[$vhost_name],
  }

}
