# == Class: lodgeit
#
class lodgeit {
  $packages = [ 'python-imaging',
                'python-jinja2',
                'python-pybabel',
                'python-werkzeug',
                'python-simplejson',
                'python-pygments']

  include apache

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

  if ! defined(Package['python-mysqldb']) {
    package { 'python-mysqldb':
      ensure   => present,
    }
  }

  package { 'SQLAlchemy':
    ensure   => present,
    provider => pip,
    require  => Class[pip],
  }

  file { '/srv/lodgeit':
    ensure => directory,
  }

  package { 'drizzle':
    ensure => absent
  }

  vcsrepo { '/tmp/lodgeit-main':
    ensure   => latest,
    provider => git,
    source   => 'https://github.com/openstack-infra/lodgeit.git',
  }

  file { '/var/backups/lodgeit_db':
    ensure => absent
  }

}
