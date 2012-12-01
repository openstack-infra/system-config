# == Class: jeepyb
#
class jeepyb (
  $git_source_repo = 'https://github.com/openstack-ci/jeepyb.git',
) {
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
