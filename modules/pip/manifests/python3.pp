# Class: pip::python3
#
class pip::python3 {
  include pip::params
  include pip::bootstrap

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
    command   => 'python3 /var/lib/ez_setup.py',
    path      => '/bin:/usr/bin',
    subscribe => Downloader[$::pip::params::ez_setup_url],
    creates   => $::pip::params::setuptools_pth,
    require   => [
      Package[$::pip::params::python3_devel_package],
      Class['pip::bootstrap'],
    ],
  }

  exec { 'install_pip':
    command   => 'python3 /var/lib/python-install/get-pip.py',
    path      => '/bin:/usr/bin',
    subscribe => Downloader[$::pip::params::git_pip_url],
    creates   => $::pip::params::pip_executable,
    require   => Exec['install_setuptools'],
  }
}
