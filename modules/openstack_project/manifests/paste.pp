# == Class: openstack_project::paste
#
class openstack_project::paste (
  $db_password,
  $db_host,
  $mysql_root_password,
  $vhost_name         = $::fqdn,
) {
  include lodgeit
  lodgeit::site { 'openstack':
    port        => '5000',
    db_password => $db_password,
    db_host     => $db_host,
    db_user     => 'openstack',
    vhost_name  => $vhost_name,
    image       => 'header-bg2.png',
    require     => Mysql::Db['openstack'],
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
