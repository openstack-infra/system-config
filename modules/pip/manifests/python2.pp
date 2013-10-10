# Class: pip::python2
#
class pip::python2 {
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
    subscribe => Downloader[$::pip::params::ez_setup_url],
    creates   => $::pip::params::setuptools_pth,
    require   => [
      Package[$::pip::params::python_devel_package],
      Class['pip::bootstrap'],
    ],
  }

  exec { 'install_pip2':
    command   => 'python /var/lib/python-install/get-pip.py',
    path      => '/bin:/usr/bin',
    subscribe => Downloader[$::pip::params::git_pip_url],
    creates   => $::pip::params::pip_executable,
    require   => Exec['install_setuptools2'],
  }
}
