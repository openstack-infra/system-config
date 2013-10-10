# Class: pip::python2
#
class pip::python2 {
  include pip::params
  pip::bootstrap{'python2':}

  package { $::pip::params::python_devel_package:
    ensure => present,
  }

  package { $::pip::params::python_setuptools_package:
    ensure => absent,
  }

  package { $::pip::params::python_pip_package:
    ensure  => absent,
  }

  exec { 'install_setuptools2':
    command   => 'python /var/lib/ez_setup.py',
    path      => '/bin:/usr/bin',
    subscribe => Exec['get_ez_setup for python2'],
    creates   => $::pip::params::setuptools_pth,
    require   => [
      Package[$::pip::params::python_devel_package],
      Pip::Bootstrap['python2'],
    ],
  }

  exec { 'install_pip2':
    command   => 'python /var/lib/get-pip.py',
    path      => '/bin:/usr/bin',
    subscribe => Exec['get_get_pip for python2'],
    creates   => $::pip::params::pip_executable,
    require   => Exec['install_setuptools2'],
  }
}
