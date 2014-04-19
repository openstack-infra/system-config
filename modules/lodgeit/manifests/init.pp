# == Class: lodgeit
#
class lodgeit {
  $packages = [ 'python-imaging',
                'python-jinja2',
                'python-pybabel',
                'python-werkzeug',
                'python-simplejson',
                'python-pygments',
                'drizzle']

  include apache
  include mysql::python
  include pip

  a2mod { 'proxy':
    ensure => present,
  }
  a2mod { 'proxy_http':
    ensure => present,
  }

  package { $packages:
    ensure => present,
  }

  package { 'SQLAlchemy':
    ensure   => present,
    provider => pip,
    require  => Class[pip],
  }

  file { '/srv/lodgeit':
    ensure => directory,
  }

  service { 'drizzle':
    ensure     => running,
    hasrestart => true,
    require    => Package['drizzle'],
  }

  vcsrepo { '/tmp/lodgeit-main':
    ensure   => latest,
    provider => git,
    source   => 'https://git.openstack.org/openstack-infra/lodgeit',
  }

}
