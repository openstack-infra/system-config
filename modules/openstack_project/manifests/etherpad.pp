class openstack_project::etherpad (
  $ssl_cert_file_contents = '',
  $ssl_key_file_contents = '',
  $ssl_chain_file_contents = '',
  $mysql_password = '',
  $mysql_root_password = '',
  $sysadmins = []
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443],
    sysadmins                 => $sysadmins
  }

  include etherpad_lite

  class { 'etherpad_lite::apache':
    ssl_cert_file           => '/etc/ssl/certs/etherpad.openstack.org.pem',
    ssl_key_file            => '/etc/ssl/private/etherpad.openstack.org.key',
    ssl_chain_file          => '/etc/ssl/certs/intermediate.pem',
    ssl_cert_file_contents  => $ssl_cert_file_contents,
    ssl_key_file_contents   => $ssl_key_file_contents,
    ssl_chain_file_contents => $ssl_chain_file_contents,
  }

  class { 'etherpad_lite::site':
    database_password => $mysql_password,
    require           => Mysql::Db['etherpad-lite'],
  }

  # Set up MySQL.
  class { 'mysql::server':
    config_hash => {
      'root_password'  => $mysql_root_password,
      'default_engine' => 'InnoDB',
      'bind_address'   => '127.0.0.1',
    }
  }
  include mysql::server::account_security
  mysql::database_user { 'root@::1':
    ensure  => absent,
    require => Class['mysql::server'],
  }

  mysql::db { 'etherpad-lite':
    user     => 'eplite',
    password => $mysql_password,
    host     => 'localhost',
    grant    => ['all'],
    charset  => 'utf8',
    require  => [
      Class['mysql::server'],
      Class['mysql::server::account_security'],
    ],
  }

  mysql_backup::backup { 'etherpad-lite':
    require  => Class['etherpad_lite'],
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
