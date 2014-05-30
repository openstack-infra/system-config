# == Define: repo
#
define livegrep::repo {
  vcsrepo { "/home/livegrep/repos/${name}":
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => github,
  }
}
