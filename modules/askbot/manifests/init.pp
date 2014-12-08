# Class: askbot
#
# This class installs Askbot and main dependencies, like
# postgresql or mysql driver, and other django libraries.
# (django-redis-cache, django-haystack, pysolr, stopforumspam)
#
# Parameters:
#   - $db_provider: database provider (mysql | pgsql)
#   - $askbot_version: pip package version of askbot
#   - $redis_enabled: set to true if askbot using redis for cache
#
# Actions:
#   - Install Askbot
#   - Install Askbot dependencies
#
class askbot (
  $db_provider = 'mysql',
  $askbot_version = '0.7.50',
  $redis_enabled = false,
) {
  include apache::mod::wsgi

  case $db_provider {
    'mysql': {
      $package_deps = [ 'python-pip', 'python-dev', 'python-mysqldb' ]
    }
    'pgsql': {
      $package_deps = [ 'python-pip', 'python-dev', 'python-psycopg2' ]
    }
    default: {
      fail("Unsupported database provider: ${db_provider}")
    }
  }

  package { $package_deps:
    ensure => present,
  }

  if $redis_enabled {
    package { 'django-redis-cache':
      ensure   => present,
      provider => 'pip',
      before   => Package['askbot'],
    }
  }

  package { [ 'django-haystack', 'pysolr' ]:
    ensure   => present,
    provider => 'pip',
    before   => Package['askbot'],
  }

  package { 'stopforumspam':
    ensure   => present,
    provider => 'pip',
    before   => Package['askbot'],
  }

  package { 'askbot':
    ensure   => $askbot_version,
    provider => 'pip',
    require  => Package[$package_deps],
  }

  file { '/srv/askbot-sites':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
}