define apt::builddep($ensure = present) {
  case $ensure {
    present: {
      exec { "Install build-deps for $name":
        path        => "/bin:/usr/bin",
        environment => "HOME=/root",
        command     => "apt-get -y --force-yes build-dep $name",
        user        => "root",
        group       => "root",
        logoutput   => on_failure,
      }
    }
    default: {
      fail "Invalid 'ensure' value '$ensure' for apt::builddep"
    }
  }
}
