class askbot::deployment(
   $serveradmin,
   $mysql_password,
   $mysql_root_password,
   $ssl_cert_file_contents = '',
   $ssl_key_file_contents = '',
   $ssl_chain_file_contents = '',
   $ssl_cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem',
   $ssl_key_file = '/etc/ssl/private/ssl-cert-snakeoil.key',
   $ssl_chain_file = ''
) {
  include askbot

  class { 'askbot::mysql':
    mysql_root_password => $mysql_root_password,
  }

  askbot::site { 'one':
    mysql_password          => $mysql_password,
    ssl_cert_file_contents  => $ssl_cert_file_contents,
    ssl_key_file_contents   => $ssl_key_file_contents,
    ssl_chain_file_contents => $ssl_chain_file_contents,
    ssl_cert_file           => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
    ssl_key_file            => '/etc/ssl/private/ssl-cert-snakeoil.key',
    ssl_chain_file          => '',
  }

  askbot::mysqldb { 'one':
    mysql_password => $mysql_password,
  }

  $askone_vhost_name = 'ask.openstack.org'
  askbot::deploy { 'one':
    vhost_name => $askone_vhost_name,
  }

  askbot::site { 'two':
    mysql_password          => $mysql_password,
    ssl_cert_file_contents  => $ssl_cert_file_contents,
    ssl_key_file_contents   => $ssl_key_file_contents,
    ssl_chain_file_contents => $ssl_chain_file_contents,
    ssl_cert_file           => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
    ssl_key_file            => '/etc/ssl/private/ssl-cert-snakeoil.key',
    ssl_chain_file          => '',
  }

  askbot::mysqldb { 'two':
    mysql_password => $mysql_password,
  }

  $asktwo_vhost_name = 'ask-secondary.openstack.org'
  askbot::deploy { 'two':
    vhost_name => $asktwo_vhost_name,
  }
}
