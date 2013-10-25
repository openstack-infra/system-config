node 'owncloud.openstack.org' {
  class { 'openstack_project::owncloud':
    mysql_host          => hiera('owncloud_db_host'),
    mysql_user          => hiera('owncloud_db_user'),
    mysql_password      => hiera('owncloud_db_password'),
    sysadmins           => hiera('sysadmins'),
  }
}
