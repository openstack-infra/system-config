# == Class: openstack_project::mirror
#
class openstack_project::mirror (
  $vhost_name = $::fqdn,
  $sysadmins = [],
) {

  $npm_docroot = $vhost_name + '/npm'

  include ::httpd

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

  class { 'openstack_project::npm_mirror':
    uri_rewrite    => $npm_docroot,
    data_directory => '/srv/static/npm_mirror',
    require        => File['/srv/static'],
  }

  ::httpd::vhost { $vhost_name:
    port     => 80,
    priority => '50',
    template => 'openstack_project/mirror.vhost.conf.erb',
    docroot  => '/srv/static/mirror/web',
    require  => [
      Class['openstack_project::pypi_mirror'],
      Class['openstack_project::npm_mirror'],
    ],
  }
}
