# == Class: openstack_project::owncloud
#
class openstack_project::owncloud (
  $sysadmins = []
) {
  class {'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
    sysadmins                 => $sysadmins,
  }
  include owncloud

  class {'owncloud::site' :
    owncloud_db_host        => $owncloud_db_host,
    owncloud_db_user        => $owncloud_db_user,
    owncloud_db_password    => $owncloud_db_password,
    sysadmins               => $sysadmins,
    owncloud_db_name        => $owncloud_db_name,
    owncloud_admin          => $owncloud_admin,
    owncloud_admin_password => $owncloud_admin_password,
    # suggested "/${root_dir}/owncloud/data"
    owncloud_directory      => $owncloud_directory,
    # the ubuntu owncloud package installs mysql-server
    # the server demands a password
    mysql_password          => $mysql_password,
  }
}
