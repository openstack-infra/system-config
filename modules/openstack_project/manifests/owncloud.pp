# == Class: openstack_project::owncloud
#
class openstack_project::owncloud (
  $sysadmins = []
) {
  class {'openstack_project::server':
    iptables_public_tcp_ports => [80],
    sysadmins                 => $sysadmins,
  }
  include openstack_project
  include owncloud

  owncloud::site {'owncloud':

  }
}
