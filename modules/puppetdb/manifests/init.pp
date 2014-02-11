# All in one class for setting up a PuppetDB instance. See README.md for more
# details.
class puppetdb(
  $listen_address            = $puppetdb::params::listen_address,
  $listen_port               = $puppetdb::params::listen_port,
  $open_listen_port          = $puppetdb::params::open_listen_port,
  $ssl_listen_address        = $puppetdb::params::ssl_listen_address,
  $ssl_listen_port           = $puppetdb::params::ssl_listen_port,
  $disable_ssl               = $puppetdb::params::disable_ssl,
  $open_ssl_listen_port      = $puppetdb::params::open_ssl_listen_port,
  $database                  = $puppetdb::params::database,
  $database_port             = $puppetdb::params::database_port,
  $database_username         = $puppetdb::params::database_username,
  $database_password         = $puppetdb::params::database_password,
  $database_name             = $puppetdb::params::database_name,
  $database_ssl              = $puppetdb::params::database_ssl,
  $database_listen_address   = $puppetdb::params::postgres_listen_addresses,
  $node_ttl                  = $puppetdb::params::node_ttl,
  $node_purge_ttl            = $puppetdb::params::node_purge_ttl,
  $report_ttl                = $puppetdb::params::report_ttl,
  $gc_interval               = $puppetdb::params::gc_interval,
  $log_slow_statements       = $puppetdb::params::log_slow_statements,
  $conn_max_age              = $puppetdb::params::conn_max_age,
  $conn_keep_alive           = $puppetdb::params::conn_keep_alive,
  $conn_lifetime             = $puppetdb::params::conn_lifetime,
  $puppetdb_package          = $puppetdb::params::puppetdb_package,
  $puppetdb_version          = $puppetdb::params::puppetdb_version,
  $puppetdb_service          = $puppetdb::params::puppetdb_service,
  $puppetdb_service_status   = $puppetdb::params::puppetdb_service_status,
  $open_postgres_port        = $puppetdb::params::open_postgres_port,
  $confdir                   = $puppetdb::params::confdir,
  $java_args                 = {}
) inherits puppetdb::params {

  # Apply necessary suffix if zero is specified.
  if $node_ttl == '0' {
    $node_ttl_real = '0s'
  } else {
    $node_ttl_real = downcase($node_ttl)
  }

  # Validate node_ttl
  validate_re ($node_ttl_real, ['^\d+(d|h|m|s|ms)$'], "node_ttl is <${node_ttl}> which does not match the regex validation")

  # Apply necessary suffix if zero is specified.
  if $node_purge_ttl == '0' {
    $node_purge_ttl_real = '0s'
  } else {
    $node_purge_ttl_real = downcase($node_purge_ttl)
  }

  # Validate node_purge_ttl
  validate_re ($node_purge_ttl_real, ['^\d+(d|h|m|s|ms)$'], "node_purge_ttl is <${node_purge_ttl}> which does not match the regex validation")

  # Apply necessary suffix if zero is specified.
  if $report_ttl == '0' {
    $report_ttl_real = '0s'
  } else {
    $report_ttl_real = downcase($report_ttl)
  }

  # Validate report_ttl
  validate_re ($report_ttl_real, ['^\d+(d|h|m|s|ms)$'], "report_ttl is <${report_ttl}> which does not match the regex validation")

  # Validate puppetdb_service_status
  if !($puppetdb_service_status in ['true', 'running', 'false', 'stopped']) {
    fail("puppetdb_service_status valid values are 'true', 'running', 'false', and 'stopped'. You provided '${puppetdb_service_status}'")
  }

  class { 'puppetdb::server':
    listen_address          => $listen_address,
    listen_port             => $listen_port,
    open_listen_port        => $open_listen_port,
    ssl_listen_address      => $ssl_listen_address,
    ssl_listen_port         => $ssl_listen_port,
    disable_ssl             => $disable_ssl,
    open_ssl_listen_port    => $open_ssl_listen_port,
    database                => $database,
    database_port           => $database_port,
    database_username       => $database_username,
    database_password       => $database_password,
    database_name           => $database_name,
    database_ssl            => $database_ssl,
    node_ttl                => $node_ttl,
    node_purge_ttl          => $node_purge_ttl,
    report_ttl              => $report_ttl,
    gc_interval             => $gc_interval,
    log_slow_statements     => $log_slow_statements,
    conn_max_age            => $conn_max_age,
    conn_keep_alive         => $conn_keep_alive,
    conn_lifetime           => $conn_lifetime,
    puppetdb_package        => $puppetdb_package,
    puppetdb_version        => $puppetdb_version,
    puppetdb_service        => $puppetdb_service,
    puppetdb_service_status => $puppetdb_service_status,
    confdir                 => $confdir,
    java_args               => $java_args,
  }

  if ($database == 'postgres') {
    class { 'puppetdb::database::postgresql':
      manage_firewall        => $open_postgres_port,
      listen_addresses       => $database_listen_address,
      database_name          => $database_name,
      database_username      => $database_username,
      database_password      => $database_password,
      before                 => Class['puppetdb::server']
    }
  }
}
