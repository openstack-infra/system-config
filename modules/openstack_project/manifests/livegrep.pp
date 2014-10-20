class openstack_project::livegrep (
)
{


  $git_repos = hiera_array("livegrep-git-repos", [])
  # Something like
  # create_resources(openstack_project::livegrep::repo, $git_repos)

  file { '/srv/git_repos':
    ensure => directory,
  }
  file { '/srv/indexes':
    ensure => directory,
  }
  file { '/opt/livegrep':
    ensure => directory,
  }
  file { '/opt/livegrep/core':
    ensure => directory,
  }
  file { '/opt/livegrep/source':
    ensure => directory,
  }
  file { '/opt/livegrep/codesearch_worker':
    ensure => directory,
  }
  file { '/opt/livegrep/web':
    ensure => directory,
  }
  file { '/opt/livegrep/core/Dockerfile':
    ensure => file,
    source => 'puppet:///modules/openstack_project/livegrep/core_Dockerfile',
  }
  file { '/opt/livegrep/codesearch_worker/Dockerfile':
    ensure => file,
    source => 'puppet:///modules/openstack_project/livegrep/codesearch_worker_Dockerfile',
  }
  file { '/opt/livegrep/web/Dockerfile':
    ensure => file,
    source => 'puppet:///modules/openstack_project/livegrep/web_Dockerfile',
  }

  vcsrepo { "/opt/livegrep/source":
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://github.com/nibalizer/livegrep.git',
  } ~>

  exec { 'build docker for livegrep base':
    provider    => 'shell',
    #refreshonly => true, #disabled for testing
    cwd         => '/opt/livegrep/core',
    command     => '/usr/bin/docker build --tag=livegrep .',
  } ~>

  exec { 'build docker for codesearch_worker':
    provider    => 'shell',
    #refreshonly => true,
    cwd         => '/opt/livegrep/codesearch_worker',
    command     => '/usr/bin/docker build --tag=livegrep:codesearch_worker .',
  } ~>

  exec { 'build docker for livegrep_web':
    provider    => 'shell',
    #refreshonly => true,
    cwd         => '/opt/livegrep/livegrep_web',
    command     => '/usr/bin/docker build --tag=livegrep:web .',
  } ~>

  docker::run { 'codesearch_worker':
    image           => 'livegrep:codesearch_worker',
    use_name        => true,
    volumes         => ['/srv/git_repos:/git_repos', '/srv/indexes:/indexes'],
    dns             => ['8.8.8.8', '8.8.4.4'],
    restart_service => true,
  } ~>

  docker::run { 'web':
    image           => 'livegrep:web',
    use_name        => true,
    links           => ['codesearch_worker:codesearch_worker'],
    volumes         => ['/srv/git_repos:/git_repos', '/srv/indexes:/indexes'],
    dns             => ['8.8.8.8', '8.8.4.4'],
    ports           => ["${::ipaddress}:8910:8910"],
    restart_service => true,
  }

}
