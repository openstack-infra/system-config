# Class: pip
#
class pip {
  include pip::params

  package { $::pip::params::python_devel_package:
    ensure => present,
  }

}
