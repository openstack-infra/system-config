# Class: pip::python2
#
class pip {
  include pip::params
  include pip::bootstrap

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
    subscribe => File['/var/lib/ez_setup.py'],
    creates   => $::pip::params::setuptools_pth,
    require   => [
      Package[$::pip::params::python3_devel_package],
      Class[Pip::bootstrap]
    ],
  }

  exec { 'install_pip2':
    command   => 'python /var/lib/git-pip.py',
    path      => '/bin:/usr/bin',
    subscribe => File['/var/lib/get-pip.py'],
    creates   => $::pip::params::pip_executable,
    require   => File[$::pip::params::setuptools_pth],
  }
}
