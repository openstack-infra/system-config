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

  exec { 'install_pip2':
    command   => 'python2 /var/lib/python-install/get-pip.py',
    path      => '/bin:/usr/bin',
    subscribe => Downloader[$::pip::params::get_pip_url],
    creates   => $::pip::params::pip_executable,
  }
}
