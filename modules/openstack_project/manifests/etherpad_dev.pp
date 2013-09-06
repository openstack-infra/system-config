class openstack_project::etherpad_dev (
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
    ssl_cert_file  => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
    ssl_key_file   => '/etc/ssl/private/ssl-cert-snakeoil.key',
    ssl_chain_file => '',
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
    require  => Class['mysql::server'],
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
