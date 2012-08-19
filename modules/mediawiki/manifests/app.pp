class mediawiki::app {

  vcsrepo { "/srv/mediawiki/w":
    ensure => latest,
    provider => git,
    source => "https://gerrit.wikimedia.org/r/p/mediawiki/core.git",
    revision => "origin/master",
  }
}
