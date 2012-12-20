define askbot::mysqldb (
  $mysql_password
) {
  # Set up mysql database
  mysql::db { "askbotdb${name}":
    user     => "askbot${name}",
    password => $mysql_password,
    host     => 'localhost',
    grant    => ['all'],
    charset  => 'utf8',
    require  => [
      Class['mysql::server'],
      Class['mysql::server::account_security'],
    ],
  }
}
