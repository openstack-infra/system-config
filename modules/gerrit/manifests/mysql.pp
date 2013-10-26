# == Class: gerrit::mysql
#
class gerrit::mysql(
  $mysql_root_password = '',
  $database_name = '',
  $database_user = '',
  $database_password = '',
) {

  class { 'mysql::server':
    config_hash => {
      'root_password'  => $mysql_root_password,
      'default_engine' => 'InnoDB',
      'bind_address'   => '127.0.0.1',
    }
  }
  include mysql::server::account_security

  mysql::db { $database_name:
    user     => $database_user,
    password => $database_password,
    host     => 'localhost',
    grant    => ['all'],
    charset  => 'latin1',
    require  => [
      Class['mysql::server'],
      Class['mysql::server::account_security'],
    ],
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
