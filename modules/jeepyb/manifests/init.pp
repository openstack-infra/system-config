# == Class: jeepyb
#
class jeepyb (
  $git_source_repo = 'https://github.com/openstack-ci/jeepyb.git',
) {

  if ! defined(Package['python-mysqldb']) {
    package { 'python-mysqldb':
      ensure   => present,
    }
  }

  if ! defined(Package['python-paramiko']) {
    package { 'python-paramiko':
      ensure   => present,
    }
  }

  if ! defined(Package['Pygithub']) {
    package { 'PyGithub':
      ensure   => latest,
      provider => pip,
      require  => Class['pip'],
    }
  }

  if ! defined(Package['gerritlib']) {
    package { 'gerritlib':
      ensure   => latest,
      provider => pip,
      require  => Class['pip'],
    }
  }

  # A lot of things need yaml, be conservative requiring this package to avoid
  # conflicts with other modules.
  if ! defined(Package['python-yaml']) {
    package { 'python-yaml':
      ensure => present,
    }
  }

  vcsrepo { '/opt/jeepyb':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => $git_source_repo,
  }

  exec { 'install_jeepyb' :
    command     => 'python setup.py install',
    cwd         => '/opt/jeepyb',
    path        => '/bin:/usr/bin',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/jeepyb'],
  }

}
