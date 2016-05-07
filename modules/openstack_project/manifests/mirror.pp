# == Class: openstack_project::mirror
#
class openstack_project::mirror (
  $vhost_name = $::fqdn,
) {

  $mirror_root = '/afs/openstack.org/mirror'
  $pypi_root = "${mirror_root}/pypi"
  $wheel_root = "${mirror_root}/wheel"
  $npm_root = "${mirror_root}/npm"
  $ceph_deb_hammer_root = "${mirror_root}/ceph-deb-hammer"
  $ceph_deb_jewel_root = "${mirror_root}/ceph-deb-jewel"

  $www_base = '/var/www'
  $www_root = "${www_base}/mirror"

  #####################################################
  # Build Apache Webroot
  file { "${www_base}":
    ensure  => directory,
    owner   => root,
    group   => root,
  }

  file { "${www_root}":
    ensure  => directory,
    owner   => root,
    group   => root,
    require => [
      File["${www_base}"],
    ]
  }

  # Create the symlink to pypi.
  file { "${www_root}/pypi":
    ensure  => link,
    target  => "${pypi_root}/web",
    owner   => root,
    group   => root,
    require => [
      File["${www_root}"],
    ]
  }

  # Create the symlink to wheel.
  file { "${www_root}/wheel":
    ensure  => link,
    target  => "${wheel_root}",
    owner   => root,
    group   => root,
    require => [
      File["${www_root}"],
    ]
  }

  # Create the symlink to centos
  file { "${www_root}/centos":
    ensure  => link,
    target  => "${mirror_root}/centos",
    owner   => root,
    group   => root,
    require => [
      File["${www_root}"],
    ]
  }

  # Create the symlink to Debian OpenStack Packaging Team reprepro.
  file { "${www_root}/debian-openstack":
    ensure  => link,
    target  => "${mirror_root}/debian-openstack",
    owner   => root,
    group   => root,
    require => [
      File["${www_root}"],
    ]
  }

  # Create the symlink to epel
  file { "${www_root}/epel":
    ensure  => link,
    target  => "${mirror_root}/epel",
    owner   => root,
    group   => root,
    require => [
      File["${www_root}"],
    ]
  }

  # Create the symlink to apt.
  file { "${www_root}/ubuntu":
    ensure  => link,
    target  => "${mirror_root}/ubuntu",
    owner   => root,
    group   => root,
    require => [
      File["${www_root}"],
    ]
  }

  file { "${www_root}/npm":
    ensure  => link,
    target  => "${npm_root}",
    owner   => root,
    group   => root,
    require => [
      File["${www_root}"],
    ]
  }

  # Create the symlink to ceph-deb-hammer.
  file { "${www_root}/ceph-deb-hammer":
    ensure  => link,
    target  => "${ceph_deb_hammer_root}",
    owner   => root,
    group   => root,
    require => [
      File["${www_root}"],
    ]
  }

  # Create the symlink to ceph-deb-jewel.
  file { "${www_root}/ceph-deb-jewel":
    ensure  => link,
    target  => "${ceph_deb_jewel_root}",
    owner   => root,
    group   => root,
    require => [
      File["${www_root}"],
    ]
  }

  # Create the symlink to Ubuntu Cloud Archive.
  file { "${www_root}/ubuntu-cloud-archive":
    ensure  => link,
    target  => "${mirror_root}/ubuntu-cloud-archive",
    owner   => root,
    group   => root,
    require => [
      File["${www_root}"],
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
  # Build VHost
  include ::httpd

  if ! defined(Httpd::Mod['rewrite']) {
    httpd::mod { 'rewrite':
      ensure => present,
    }
  }

  if ! defined(Httpd::Mod['substitute']) {
    httpd::mod { 'substitute':
      ensure => present,
    }
  }

  ::httpd::vhost { $vhost_name:
    port     => 80,
    priority => '50',
    docroot  => "${www_root}",
    template => 'openstack_project/mirror.vhost.erb',
    require  => [
      File["${www_root}"],
    ]
  }
}
