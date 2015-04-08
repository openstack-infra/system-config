# == Class: openstack_project::paste
#
class openstack_project::paste (
  $db_password,
  $mysql_root_password,
  $db_host            = 'localhost',
  $db_user            = 'openstack',
  $mysql_bind_address = '127.0.0,1',
  $port               = '5000',
  $image              = 'header-bg2.png',
  $vhost_name         = 'paste.openstack.org',
  $default_engine     = 'InnoDB',
) {
  include lodgeit
  lodgeit::site { 'openstack':
    port        => $port,
    db_password => $db_password,
    db_host     => $db_host,
    db_user     => $db_user,
    vhost_name  => $vhost_name,
    image       => $image,
    require     => mysql::db['openstack'],
  }

  class { 'mysql::server':
    config_hash => {
      'root_password'  => $mysql_root_password,
      'default_engine' => $default_engine,
      'bind_address'   => $mysql_bind_address,
    }
  }

  include mysql::server::account_security
  mysql::db { 'openstack':
    user     => $db_user,
    password => $db_password,
    host     => $db_host,
    grant    => ['all'],
    charset  => 'utf8',
    require  => [
      Class['mysql::server'],
      Class['mysql::server::account_security'],
    ],
  }
}
