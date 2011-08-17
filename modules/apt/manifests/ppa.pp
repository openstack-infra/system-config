define apt::ppa($ensure = present) {
  $has_ppa = "/usr/bin/test -f /etc/apt/sources.list.d/`echo $name | cut -f2 -d: | sed 's/\//-/'`*list"
  case $ensure {
    present: {
      exec { "Add $name PPA":
        path        => "/usr/sbin:/usr/bin:/sbin:/bin",
        environment => "HOME=/root",
        command     => "add-apt-repository $name ; apt-get update",
        user        => "root",
        group       => "root",
        logoutput   => on_failure,
        unless      => "$has_ppa",
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
        unless      => "$has_ppa",
      }
    }
    default: {
      fail "Invalid 'ensure' value '$ensure' for ppa"
    }
  }
}
