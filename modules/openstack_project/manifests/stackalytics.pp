# == Class: openstack_project::stackalytics
#
class openstack_project::stackalytics(
  $stackalytics_ssh_private_key,
  $sysadmins = [],
) {

  class { 'openstack_project::server':
    sysadmins                 => $sysadmins,
    iptables_public_tcp_ports => [80],
  }

  class { '::stackalytics':
    stackalytics_ssh_private_key => $stackalytics_ssh_private_key,
  }

}
