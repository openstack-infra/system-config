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

  vcsrepo { "/opt/zuul":
    ensure => latest,
    provider => git,
    revision => "master",
    source => "https://github.com/openstack-ci/zuul.git",
  }

  exec { "install_zuul":
    command => "python setup.py install",
    cwd => "/opt/zuul",
    path => "/bin:/usr/bin",
    refreshonly => true,
    subscribe => Vcsrepo["/opt/zuul"],
  }

  file { "/etc/zuul":
    ensure => "directory",
  }

# TODO: We should put in  notify either Service['zuul'] or Exec['zuul-reload']
#       at some point, but that still has some problems.
  file { "/etc/zuul/zuul.conf":
    owner => 'jenkins',
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
