# Class: pip
#
class pip {
  include pip::params

  package { $::pip::params::python_devel_package:
    ensure => present,
  }

  package { $::pip::params::python_pip_package:
    ensure  => present,
    require => Package[$::pip::params::python_devel_package]
  }

  package { 'setuptools':
    ensure   => latest,
    provider => pip,
    require  => Package[$::pip::params::python_pip_package],
  }

  if ($::operatingsystem in ['CentOS', 'RedHat']) {

    file { '/usr/bin/pip':
      ensure => 'link',
      target => '/usr/bin/pip-python',
    }

  }

}
