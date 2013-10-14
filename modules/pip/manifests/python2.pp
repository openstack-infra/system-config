# Class: pip::python2
#
class pip::python2 {
  include pip::params
  pip::bootstrap::pip_bootstrap{'installing python2 pip':}
  
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
    subscribe => Exec['get_ez_setup'],
    creates   => $::pip::params::setuptools_pth,
    require   => [
      Package[$::pip::params::python_devel_package],
      Pip::Bootstrap::Pip_bootstrap['installing python2 pip'],
    ],
  }


  exec { 'install_pip2':
    command   => 'python /var/lib/git-pip.py',
    path      => '/bin:/usr/bin',
    subscribe => Exec['get_get_pip'],
    creates   => $::pip::params::pip_executable,
    require   => Exec['install_setuptools2'],
  }
}
