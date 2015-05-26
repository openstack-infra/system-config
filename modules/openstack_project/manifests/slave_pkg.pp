# == Class: openstack_project::slave_pkg
#
class openstack_project::slave_pkg {
  $packages = [
    'mock',
    'python-lzma',
  ]

  package { $packages:
    ensure  => present,
    require => Group['mock'],
  }

  group { 'mock':
    ensure => present,
  }

  # Jenkins already exists, so we need to append our mock group.
  User <| title == jenkins |> {
    groups  +> 'mock',
    require => Group['mock'],
  }

  # TODO(pabelanger): Example chroot using mock, perhaps move it some place else?
  exec { '/usr/bin/mock init -r fedora-20-x86_64 --resultdir=/home/jenkins/mock/':
    require => [
      Package[$packages],
    ],
    user => 'jenkins',
  }
}
