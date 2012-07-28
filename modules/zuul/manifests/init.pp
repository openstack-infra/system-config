class zuul (
    $jenkins_server,
    $jenkins_user,
    $jenkins_apikey,
    $gerrit_server,
    $gerrit_user
) {
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

# TODO: We should put in  notify either Service['zuul'] or Exec['zuul-reload']
#       at some point, but that still has some problems.
  file { "/etc/zuul/zuul.conf":
    owner => 'jenkins',
    group => 'jenkins',
    mode => 400,
    ensure => 'present',
    content => template('zuul/zuul.conf.erb'),
    require => File["/etc/zuul"],
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
