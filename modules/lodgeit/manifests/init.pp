class lodgeit {
  $packages = [ "nginx",
                "python-imaging",
                "python-jinja2",
                "python-pybabel",
                "python-werkzeug",
                "python-simplejson",
                "python-pygments",
                "mercurial",
                "drizzle",
                "python-mysqldb" ]

  include pip

  package { $packages: ensure => present }

  package { 'SQLAlchemy':
    provider => pip,
    ensure => present,
    require => Class[pip]
  }

  file { '/srv/lodgeit':
    ensure => directory
  }

  service { 'drizzle':
    ensure => running,
    hasrestart => true
  }

  service { "nginx":
    ensure => running,
    hasrestart => true
  }

# if we already have the git repo the pull updates

  exec { "update_lodgeit":
    command => "git pull --ff-only",
    cwd => "/tmp/lodgeit-main",
    path => "/bin:/usr/bin",
    onlyif => "test -d /tmp/lodgeit-main"
  }

# otherwise get a new clone of it

  exec { "get_lodgeit":
    command => "git clone git://github.com/openstack-ci/lodgeit.git /tmp/lodgeit-main",
    path => "/bin:/usr/bin",
    onlyif => "test ! -d /tmp/lodgeit-main"
  }

# create initial git DB backup location

  exec { "create_db_backup":
    command => "git init /var/backups/lodgeit_db",
    path => "/bin:/usr/bin",
    onlyif => "test ! -d /var/backups/lodgeit_db"
  }

}
