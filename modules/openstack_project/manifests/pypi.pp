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

  if ! defined(File['/srv/static']) {
    file { '/srv/static':
      ensure => directory,
    }
  }

  class { 'openstack_project::pypi_mirror':
    data_directory => '/srv/static/mirror',
    require        => File['/srv/static'],
  }

  include ::httpd
  ::httpd::vhost { $vhost_name:
    port     => 80,
    priority => '50',
    docroot  => '/srv/static/mirror/web',
    require  => Class["Openstack_project::Pypi_mirror"],
  }
}
