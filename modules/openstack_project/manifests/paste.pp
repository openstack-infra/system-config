# == Class: openstack_project::paste
#
class openstack_project::paste (
  $db_host,
  $db_password,
  $sysadmins = []
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
    sysadmins                 => $sysadmins,
  }
  include lodgeit
  lodgeit::site { 'openstack':
    db_host     => $db_host,
    db_password => $db_password,
    port        => '5000',
    image       => 'header-bg2.png',
  }
}
