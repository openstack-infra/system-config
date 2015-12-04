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
  $www_root = "${pypi_root}/web"
  $wheel_root = "${www_root}/wheel"

  if ! defined(File[$mirror_root]) {
    file { $mirror_root:
      ensure => directory,
    }
  }

  class { 'openstack_project::pypi_mirror':
    data_directory => "${pypi_root}",
    require        => File[$mirror_root]
  }

  class { 'openstack_project::wheel_mirror':
    data_directory => "${wheel_root}",
    require        => Class['Openstack_project::Pypi_mirror'],
  }

  include ::httpd

  if ! defined(Httpd::Mod['rewrite']) {
    httpd::mod { 'rewrite':
      ensure => present,
    }
  }

  ::httpd::vhost { $vhost_name:
    port     => 80,
    priority => '50',
    docroot  => $www_root,
    require  => Class['Openstack_project::Pypi_mirror'],
    template => 'openstack_project/pypi.vhost.erb',
  }

  file { "${www_root}/robots.txt":
    ensure   => present,
    owner    => 'root',
    group    => 'root',
    mode     => '0444',
    source   => 'puppet:///modules/openstack_project/disallow_robots.txt',
    require  => Class['Openstack_project::Pypi_mirror'],
  }
}
