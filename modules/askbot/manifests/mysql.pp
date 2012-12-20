define askbot::mysql (
  $mysql_password,
  $mysql_root_password,
) {
  # Set up mysql database
  mysql::db { "askbotdb${name}":
    user     => 'askbot',
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
