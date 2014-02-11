# Class for creating the PuppetDB postgresql database. See README.md for more
# information.
class puppetdb::database::postgresql(
  $manage_firewall   = $puppetdb::params::open_postgres_port,
  $listen_addresses  = $puppetdb::params::database_host,
  $database_name     = $puppetdb::params::database_name,
  $database_username = $puppetdb::params::database_username,
  $database_password = $puppetdb::params::database_password,
) inherits puppetdb::params {

  # get the pg server up and running
  class { '::postgresql::server':
    ip_mask_allow_all_users => '0.0.0.0/0',
    listen_addresses        => $listen_addresses,
    manage_firewall         => $manage_firewall,
  }

  # create the puppetdb database
  postgresql::server::db { $database_name:
    user     => $database_username,
    password => $database_password,
    grant    => 'all',
  }
}
