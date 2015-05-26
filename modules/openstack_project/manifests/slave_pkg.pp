# == Class: openstack_project::slave_pkg
#
class openstack_project::slave_pkg {
  $packages = [
    'debhelper',
    'git-buildpackage',
    'sphinx-doc',
  ]

  package { $packages:
    ensure  => present,
  }
}
