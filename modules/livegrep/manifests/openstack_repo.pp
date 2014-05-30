# == Define: openstack_repo
#
define livegrep::openstack_repo {
  vcsrepo { "/home/livegrep/repos/${name}":
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => "https://github.com/openstack/${name}",
  }
}
