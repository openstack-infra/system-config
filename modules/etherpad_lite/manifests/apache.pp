class etherpad_lite::apache (
  $vhost_name = $fqdn,
  $ssl_cert_file='',
  $ssl_key_file='',
  $ssl_chain_file='',
  $ssl_cert_file_contents='', # If left empty puppet will not create file.
  $ssl_key_file_contents='', # If left empty puppet will not create file.
  $ssl_chain_file_contents='' # If left empty puppet will not create file.
) {

  apache::vhost { $vhost_name:
    port => 443,
    docroot => 'MEANINGLESS ARGUMENT',
    priority => '50',
    template => 'etherpad_lite/etherpadlite.vhost.erb',
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

  file { "/etc/ssl/certs/${vhost_name}.pem":
    ensure  => present,
    replace => true,
    owner   => 'root',
    mode    => 0600,
    content => template('etherpad_lite/eplite.crt.erb'),
    require => File['/etc/ssl/certs'],
  }

  file { "/etc/ssl/private/${vhost_name}.key":
    ensure  => present,
    replace => true,
    owner   => 'root',
    mode    => 0600,
    content => template('etherpad_lite/eplite.key.erb'),
    require => File['/etc/ssl/private'],
  }


  if $ssl_cert_file_contents != '' {
    file { $ssl_cert_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_cert_file_contents,
      before  => Apache::Vhost[$vhost_name],
    }
  }

  if $ssl_key_file_contents != '' {
    file { $ssl_key_file:
      owner   => 'root',
      group   => 'ssl-cert',
      mode    => '0640',
      content => $ssl_key_file_contents,
      require => Package['ssl-cert'],
      before  => Apache::Vhost[$vhost_name],
    }
  }

  if $ssl_chain_file_contents != '' {
    file { $ssl_chain_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_chain_file_contents,
      before  => Apache::Vhost[$vhost_name],
    }
  }


}
