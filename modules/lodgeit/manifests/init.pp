class lodgeit {
  $packages = [ "nginx",
                "python-imaging",
                "python-pip",
                "python-jinja2",
                "python-pybabel",
                "python-werkzeug",
                "python-simplejson",
                "python-pygments",
                "mercurial",
                "drizzle",
                "python-mysqldb" ]

  package { $packages: ensure => latest }

  package { 'SQLAlchemy':
    provider => pip,
    ensure => present,
    require => Package[python-pip]
  }

  file { '/srv/lodgeit':
    ensure => directory
  }

  service { 'drizzle':
    ensure => running,
    hasrestart => true
  }


# if we already have the mercurial repo the pull updates

  exec { "update_lodgeit":
    command => "hg pull /tmp/lodgeit-main",
    path => "/bin:/usr/bin",
    onlyif => "test -d /tmp/lodgeit-main"
  }

# otherwise get a new clone of it

  exec { "get_lodgeit":
    command => "hg clone http://dev.pocoo.org/hg/lodgeit-main /tmp/lodgeit-main",
    path => "/bin:/usr/bin",
    onlyif => "test ! -d /tmp/lodgeit-main"
  }

  service { 'nginx':
    ensure => running,
    hasrestart => true
  }
}
