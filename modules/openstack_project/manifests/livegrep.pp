# == Class: openstack_project::livegrep
#
class openstack_project::livegrep (
  $sysadmins = []
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [8080],
    sysadmins                 => $sysadmins,
  }
  include livegrep
}
