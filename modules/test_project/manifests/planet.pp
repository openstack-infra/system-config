# == Class: test_project::planet
#
class test_project::planet (
  $sysadmins = []
) {
  class { 'test_project::server':
    iptables_public_tcp_ports => [80],
    sysadmins                 => $sysadmins,
  }
  include ::planet

  planet::site { 'openstack':
    git_url => 'git://git.openstack.org/openstack/openstack-planet',
  }
}
