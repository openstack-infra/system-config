# == Class: openstack_project::owncloud
#
class openstack_project::owncloud (
  $sysadmins = [],
  $mysql_password = '',
) {
  class {'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
    sysadmins                 => $sysadmins,
  }
  include owncloud

  class {'owncloud' :
    sysadmins               => $sysadmins,
    # the ubuntu owncloud package installs mysql-server
    # the server demands a password
    mysql_password          => $mysql_password,
  }
}
