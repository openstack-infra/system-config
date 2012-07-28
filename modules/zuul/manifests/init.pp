class zuul ()
{
  $packages = ["python-webob",
               "python-daemon",
               "python-paste"]

  package { $packages:
    ensure => "present",
  }

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

  file { "/var/log/zuul":
    ensure => "directory",
    owner => 'jenkins'
  }

  file { "/var/run/zuul":
    ensure => "directory",
    owner => 'jenkins'
  }

  file { "/var/lib/zuul":
    ensure => "directory",
    owner => 'jenkins'
  }

  file { "/etc/init.d/zuul/":
    owner => 'root',
    group => 'root',
    mode => 555,
    ensure => 'present',
    source => 'puppet:///modules/zuul/zuul.init',
  }

  exec { "zuul-reload":
      command => '/etc/init.d/zuul reload',
      require => File['/etc/init.d/zuul'],
      refreshonly => true,
  }

  service { 'zuul':
    name       => 'zuul',
    enable     => true,
    hasrestart => true,
    require => File['/etc/init.d/zuul'],
  }

}
