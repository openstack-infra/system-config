# == Class: openstack_project::mirror
#
class openstack_project::mirror (
  $vhost_name = $::fqdn,
) {

  $mirror_root = '/srv/static'
  $www_root = "${mirror_root}/www"
  $pypi_root = "${mirror_root}/pypi"

  #####################################################
  # Build File Structure

  if ! defined(File["${mirror_root}"]) {
    file { "${mirror_root}":
      ensure => directory,
    }
  }

  file { "${www_root}":
    ensure  => directory,
    owner   => root,
    group   => root,
    require => File["${mirror_root}"],
  }

  # Make the webroot look like the http site.
  file { "${www_root}/pypi":
    ensure  => link,
    target  => "${pypi_root}/web",
    owner   => root,
    group   => root,
    require => [
      File["${www_root}"],
      Class['Openstack_project::Pypi_mirror'],
    ]
  }

  file { "${www_root}/robots.txt":
    ensure   => present,
    owner    => 'root',
    group    => 'root',
    mode     => '0444',
    source   => 'puppet:///modules/openstack_project/disallow_robots.txt',
    require  => File["${www_root}"],
  }


  #####################################################
  # Build Mirrors

  class { 'openstack_project::pypi_mirror':
    data_directory => "${pypi_root}",
    require        => File[$mirror_root],
  }


  #####################################################
  # Build VHost
  include ::httpd

  ::httpd::vhost { $vhost_name:
    port     => 80,
    priority => '50',
    docroot  => "${www_root}",
    template => 'openstack_project/mirror.vhost.erb',
    require  => [
      File["${www_root}"],
      Class['Openstack_project::Pypi_mirror'],
    ]
  }

}
