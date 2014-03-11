# == Class: openstack_project::paste
#
class openstack_project::paste (
  $sysadmins = []
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
    sysadmins                 => $sysadmins,
  }
  include lodgeit
  lodgeit::site { 'openstack':
    port  => '5000',
    image => 'header-bg2.png',
  }

  lodgeit::site { 'drizzle':
    port => '5001',
  }
}
