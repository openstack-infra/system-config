# == Class: openstack_project::pholio
#

class openstack_project::pholio (
  $sysadmins = []
) {

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443],
    sysadmins                 => $sysadmins,
  }

  include ::phabricator

}
