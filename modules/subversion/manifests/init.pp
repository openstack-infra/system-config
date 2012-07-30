class subversion {
  package { ["subversion"]:
    ensure => latest;
  }
}
