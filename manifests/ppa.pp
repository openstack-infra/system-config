define ppa($ensure = present) {
  case $ensure {
    present: {
      exec { "Add $name PPA":
        path        => "/bin:/usr/bin",
        environment => "HOME=/root",
        command     => "add-apt-repository $name",
        user        => "root",
        group       => "root",
        logoutput   => on_failure,
      }
    }
    absent:  {
      exec { "Add $name PPA":
        path        => "/bin:/usr/bin",
        environment => "HOME=/root",
        command     => "add-apt-repository --remove $name",
        user        => "root",
        group       => "root",
        logoutput   => on_failure,
      }
    }
    default: {
      fail "Invalid 'ensure' value '$ensure' for ppa"
    }
  }
}
