# == Class: openstack_project::puppetdb
#
class openstack_project::puppetdb (
  $sysadmins = []
) {

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [4505, 4506, 8140],
    sysadmins                 => $sysadmins,
  }

  class { '::puppetdb': }

}
