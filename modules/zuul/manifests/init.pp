class zuul ()
{
  # if we already have the repo the pull updates

  exec { "update_zuul":
    command => "git pull --ff-only",
    cwd => "/opt/zuul",
    path => "/bin:/usr/bin",
    onlyif => "test -d /opt/zuul",
    before => Exec["get_zuul"],
  }

  # otherwise get a new clone of it

  exec { "get_zuul":
    command => "git clone https://github.com/openstack-ci/zuul /opt/zuul",
    path => "/bin:/usr/bin",
    onlyif => "test ! -d /opt/zuul"
  }

  exec { "install_zuul":
    command => "python setup.py install",
    cwd => "/opt/zuul",
    path => "/bin:/usr/bin",
    subscribe => [ Exec["get_zuul"], Exec["update_zuul"] ],
  }

  file { "/etc/zuul":
    ensure => "directory",
  }
}
