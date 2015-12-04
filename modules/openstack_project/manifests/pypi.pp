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

  $mirror_root = '/srv/static'
  $pypi_root = "${mirror_root}/mirror"

  if ! defined(File[$mirror_root]) {
    file { $mirror_root:
      ensure => directory,
    }
  }

  class { 'openstack_project::pypi_mirror':
    data_directory => "${pypi_root}",
    require        => File[$mirror_root]
  }

  include ::httpd

  ::httpd::vhost { $vhost_name:
    port     => 80,
    priority => '50',
    docroot  => "${pypi_root}/web",
    require  => Class['Openstack_project::Pypi_mirror'],
  }

  file { "${pypi_root}/web/robots.txt":
    ensure   => present,
    owner    => 'root',
    group    => 'root',
    mode     => '0444',
    source   => 'puppet:///modules/openstack_project/disallow_robots.txt',
    require  => Class['Openstack_project::Pypi_mirror'],
  }
}
