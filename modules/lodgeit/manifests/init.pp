class lodgeit {
  package { 'nginx':
    ensure => present
  }

  package { 'python-imaging':
    ensure => present
  }

  package { 'python-pip':
    ensure => present
  }

  package { 'SQLAlchemy':
    provider => pip,
    ensure => present,
    require => Package[python-pip]
  }

  package { 'python-jinja2':
    ensure => present
  }

  package { 'python-pybabel':
    ensure => present
  }

  package { 'python-werkzeug':
    ensure => present
  }

  package { 'python-simplejson':
    ensure => present
  }

  package { 'python-pygments':
    ensure => present
  }

  package { 'mercurial':
    ensure => present
  }

  package { 'drizzle':
    ensure => present
  }

  package { 'python-mysqldb':
    ensure => present
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

  lodgeit::site { "openstack": 
    port => "5000"
  }

  lodgeit::site { "drizzle": 
    port => "5001"
  }

  service { 'nginx':
    ensure => running,
    hasrestart => true
  }
}
