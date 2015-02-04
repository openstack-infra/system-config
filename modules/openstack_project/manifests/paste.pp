# == Class: openstack_project::paste
#
class openstack_project::paste (
  $db_password,
  $mysql_root_password,
  $sysadmins = []
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
    sysadmins                 => $sysadmins,
  }
  include lodgeit
  lodgeit::site { 'openstack':
    db_host     => 'localhost',
    db_password => $db_password,
    port        => '5000',
    image       => 'header-bg2.png',
    require     => mysql::db['openstack'],
  }

  class { 'mysql::server':
    config_hash => {
      'root_password'  => $mysql_root_password,
      'default_engine' => 'InnoDB',
      'bind_address'   => '127.0.0.1',
    }
  }

  include mysql::server::account_security
  mysql::db { 'openstack':
    user     => 'openstack',
    password => $db_password,
    host     => 'localhost',
    grant    => ['all'],
    charset  => 'utf8',
    require  => [
      Class['mysql::server'],
      Class['mysql::server::account_security'],
    ],
  }
}
