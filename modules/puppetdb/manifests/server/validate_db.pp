# This validates a database connection. See README.md for more details.
class puppetdb::server::validate_db(
  $database          = $puppetdb::params::database,
  $database_host     = $puppetdb::params::database_host,
  $database_port     = $puppetdb::params::database_port,
  $database_username = $puppetdb::params::database_username,
  $database_password = $puppetdb::params::database_password,
  $database_name     = $puppetdb::params::database_name,
  $database_ssl      = $puppetdb::params::database_ssl
) inherits puppetdb::params {

  # We don't need any validation for the embedded database, presumably.
  if ($database == 'postgres' and (
    $database_password != undef and $database_ssl == false)
  ) {
    postgresql::validate_db_connection { 'validate puppetdb postgres connection':
      database_host     => $database_host,
      database_port     => $database_port,
      database_username => $database_username,
      database_password => $database_password,
      database_name     => $database_name,
    }
  }
}
