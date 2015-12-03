# == Class: openstack_project::pypi
#
class openstack_project::pypi (
  $vhost_name = $::fqdn,
  $sysadmins = [],
  $root_data_directory = '/srv/static'
) {

  if ! defined(File[$root_data_directory]) {
    file { $root_data_directory:
      ensure => directory,
    }
  }

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80],
    sysadmins                 => $sysadmins,
  }

  class { 'openstack_project::pypi_mirror':
    vhost_name => $vhost_name,
    data_directory => "${root_data_directory}/pypi"
  }
}
