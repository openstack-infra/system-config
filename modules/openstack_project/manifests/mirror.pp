# == Class: openstack_project::mirror
#
class openstack_project::mirror (
  $vhost_name = $::fqdn,
  $sysadmins = [],
) {

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80],
    sysadmins                 => $sysadmins,
  }

  include ::httpd

  ::httpd::mod { ['version', 'alias']: }

  $base = '/srv/static'
  $docroot = "${base}/docroot"
  $pypi_docroot = "${base}/mirror"

  if ! defined(File[$base]) {
    file { $base:
      ensure => directory,
    }
  }

  file { $docroot:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    require => File[$base],
  }

  ::httpd::vhost { $vhost_name:
    port     => 80,
    priority => '50',
    docroot  => $docroot,
    template => 'openstack_project/mirror.vhost.erb',
    require  => File[$docroot],
  }

  class { 'openstack_project::pypi_mirror':
    data_directory => $pypi_docroot,
    require        => File[$base],
  }
}
