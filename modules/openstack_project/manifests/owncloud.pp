# == Class: openstack_project::owncloud
#
class openstack_project::owncloud (
  $owncloud_db_host = '',
  $owncloud_db_user = '',
  $owncloud_db_password = '',
  $sysadmins = [],
  $mysql_password = '',
) {
  class {'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
    sysadmins                 => $sysadmins,
  }
  include owncloud

  class {'owncloud' :
    owncloud_db_host        => $owncloud_db_host,
    owncloud_db_user        => $owncloud_db_user,
    owncloud_db_password    => $owncloud_db_password,
    sysadmins               => $sysadmins,
    # the ubuntu owncloud package installs mysql-server
    # the server demands a password
    mysql_password          => $mysql_password,
  }
}
