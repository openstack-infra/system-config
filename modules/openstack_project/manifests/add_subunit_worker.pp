# == Defined type for openstack_project::subunit_worker class
#
define openstack_project::add_subunit_worker($config_file,$db_host,$db_pass) {
  subunit2sql::worker { $name:
    config_file        => $config_file,
    db_host            => $db_host,
    db_pass            => $db_pass,
  }
}
