class mediawiki::app {
  include git

  git::clone { "mediawiki":
    directory => "/srv/mediawiki/w",
    branch => "master",
    origin => "https://gerrit.wikimedia.org/r/p/mediawiki/core.git";
  }
}
