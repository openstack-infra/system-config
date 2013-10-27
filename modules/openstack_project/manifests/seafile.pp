# == Class: openstack_project::seafile
#
class openstack_project::seafile (
  $sysadmins = []
) {
  class {'openstack_project::server':
    iptables_public_tcp_ports => [80, 443, 8000, 8082],
    sysadmins                 => $sysadmins,
  }
  indclude openstack_project
  include seafile

  seafile::site {'seafile':

  }
}
