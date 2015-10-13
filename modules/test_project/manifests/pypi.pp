# == Class: test_project::pypi
#
class test_project::pypi (
  $vhost_name = $::fqdn,
  $sysadmins = [],
) {

  class { 'test_project::server':
    iptables_public_tcp_ports => [22, 80],
    sysadmins                 => $sysadmins,
  }

  class { 'test_project::pypi_mirror':
    vhost_name => $vhost_name,
  }
}
