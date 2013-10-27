node 'seafile.openstack.org' {
  class { 'openstack_project::seafile' :
    seafile_db_host     => hiera('seafile_db_host'),
    seafile_db_user     => hiera('seafile_db_user'),
    seafile_db_password => hiera('seafile_db_password'),
    sysadmins      => hiera('sysadmins'),
  }
}
