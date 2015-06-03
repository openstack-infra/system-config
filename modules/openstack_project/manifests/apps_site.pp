# == Class: openstack_project::apps_site
#
class openstack_project::apps_site (
  $sysadmins = []
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
    sysadmins                 => $sysadmins,
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
