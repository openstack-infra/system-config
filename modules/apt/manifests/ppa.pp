define apt::ppa($ensure = present) {
  case $ensure {
    present: {
      exec { "Add $name PPA":
        path        => "/usr/sbin:/usr/bin:/sbin:/bin",
        environment => "HOME=/root",
        command     => "add-apt-repository $name ; apt-get update",
        user        => "root",
        group       => "root",
        logoutput   => on_failure,
      }
    }
    absent:  {
      exec { "Add $name PPA":
        path        => "/usr/sbin:/usr/bin:/sbin:/bin",
        environment => "HOME=/root",
        command     => "add-apt-repository --remove $name ; apt-get update",
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
