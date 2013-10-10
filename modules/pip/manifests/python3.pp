# Class: pip::python3
#
class pip::python3 {
  include pip::params
  pip::bootstrap{'installing python3 pip':}

  package { $::pip::params::python3_devel_package:
    ensure => present,
  }

  package { $::pip::params::python3_pip_package:
    ensure  => absent,
  }

  package { $::pip::params::python3_setuptools_package:
    ensure => absent,
  }

  exec { 'install_setuptools':
    command   => 'python /var/lib/ez_setup.py',
    path      => '/bin:/usr/bin',
    subscribe => Exec['get_ez_setup'],
    creates   => $::pip::params::setuptools_pth,
    require   => [
      Package[$::pip::params::python3_devel_package],
      Pip::Bootstrap['installing python3 pip'],
    ],
  }

  exec { 'install_pip':
    command   => 'python /var/lib/git-pip.py',
    path      => '/bin:/usr/bin',
    subscribe => Exec['get_get_pip'],
    creates   => $::pip::params::pip_executable,
    require   => Exec['install_setuptools'],
  }
}
