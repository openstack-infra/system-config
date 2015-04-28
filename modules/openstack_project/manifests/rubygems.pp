# == Class: openstack_project::rubygems
#
class openstack_project::rubygems (
  $vhost_name = $::fqdn,
  $sysadmins = [],
) {

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80],
    sysadmins                 => $sysadmins,
  }

  class { 'openstack_project::rubygems_mirror':
    vhost_name => $vhost_name,
  }
}
