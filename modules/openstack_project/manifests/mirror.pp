# == Class: openstack_project::mirror
#
class openstack_project::mirror (
  $vhost_name = $::fqdn,
) {

  include ::httpd
  
  ::httpd::mod { ['version', 'alias']: }

  $base = '/srv/static'
  $docroot = "${base}/docroot"
  $pypi_docroot = "${base}/mirror"
  $npm_docroot = "${base}/npm"

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

  file { "${docroot}/robots.txt":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    source  => 'puppet:///modules/openstack_project/disallow_robots.txt',
    require => File[$docroot],
  }

  file { "${docroot}/pypi":
    ensure  => 'link',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    target  => "$pypi_docroot/web",
    require => File[$docroot],
  }

  file { "${docroot}/npm":
    ensure  => 'link',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    target  => $npm_docroot,
    require => File[$docroot],
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

  class { 'openstack_project::npm_mirror':
    uri_rewrite    => "${vhost_name}/npm",
    data_directory => $npm_docroot,
    require        => File[$base],
  }
}
