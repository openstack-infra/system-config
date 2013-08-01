# Class: pip
#
class pip::python3 {
  include pip::params

  package { $::pip::params::python3_devel_package:
    ensure => present,
  }

  package { $::pip::params::python3_pip_package:
    ensure  => present,
    require => Package[$::pip::params::python3_devel_package]
  }

}
