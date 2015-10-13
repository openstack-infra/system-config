# == Class: openstack_project::pypi
#
class openstack_project::pypi (
  $vhost_name = $::fqdn,
  $sysadmins = [],
) {

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80],
    sysadmins                 => $sysadmins,
  }

  class { 'openstack_project::pypi_mirror':
    vhost_name => $vhost_name,
  }
}
