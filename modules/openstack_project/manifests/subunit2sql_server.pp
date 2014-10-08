class openstack_project::subunit2sql_server (
  $subunit2sql_db_uri,
) {
  class { 'subunit2sql::server':
    subunit2sql_db_uri  => $subunit2sql_db_uri,
  }
}
