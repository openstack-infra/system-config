# == Class: openstack_project::slave_pkg
#
class openstack_project::slave_pkg {
  $packages = [
    'build-essential',
    'debhelper',
    'debootstrap',
    'fakeroot',
    'git-buildpackage',
    'libwww-perl',
    'python-sphinx',
    'sbuild',
  ]

  package { $packages:
    ensure  => present,
  }

  # Jenkins already exists, so we need to append our sbuild group.
  User <| title == jenkins |> {
    groups  +> 'sbuild',
    require => Package[$packages],
  }

  $dist = [
    'sid',
  ]

  # TODO(pabelanger): We should bootstrap our chroots with disk-builder (nodepool).
  exec { "sbuild-createchroot --make-sbuild-tarball=/var/lib/sbuild/${dist}-amd64.tar.gz sid `mktemp -d` http://ftp.debian.org/debian":
    require => Packages[$packages],
  }
}
