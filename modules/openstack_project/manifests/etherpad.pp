class openstack_project::etherpad (
  $mysql_password,
  $ssl_cert_file = '/etc/ssl/certs/etherpad.openstack.org.pem',
  $ssl_key_file = '/etc/ssl/private/etherpad.openstack.org.key',
  $ssl_chain_file = '/etc/ssl/certs/intermediate.pem',
  $ssl_cert_file_contents = '',
  $ssl_key_file_contents = '',
  $ssl_chain_file_contents = '',
  $mysql_host = 'localhost',
  $mysql_user = 'eplite',
  $mysql_db_name = 'etherpad-lite'
) {
  class { 'etherpad_lite':
    ep_ensure      => 'latest',
    eplite_version => 'cc9f88e7ed4858b72feb64c99beb3e13445ab6d9',
    nodejs_version => 'system',
  }

  class { 'etherpad_lite::apache':
    ssl_cert_file           => $ssl_cert_file,
    ssl_key_file            => $ssl_key_file,
    ssl_chain_file          => $ssl_chain_file,
    ssl_cert_file_contents  => $ssl_cert_file_contents,
    ssl_key_file_contents   => $ssl_key_file_contents,
    ssl_chain_file_contents => $ssl_chain_file_contents,
  }

  class { 'etherpad_lite::site':
    etherpad_title    => 'OpenStack Etherpad',
    database_host     => $mysql_host,
    database_user     => $mysql_user,
    database_name     => $mysql_db_name,
    database_password => $mysql_password,
  }

  etherpad_lite::plugin { 'ep_headings':
    require => Class['etherpad_lite'],
  }

  mysql_backup::backup_remote { 'etherpad-lite':
    database_host     => $mysql_host,
    database_user     => $mysql_user,
    database_password => $mysql_password,
    num_backups       => '10',
    require           => Class['etherpad_lite'],
  }

  include bup
  bup::site { 'rs-ord':
    backup_user   => 'bup-etherpad',
    backup_server => 'ci-backup-rs-ord.openstack.org',
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
