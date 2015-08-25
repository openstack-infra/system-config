# Class to configure hound on a node.
class openstack_project::codesearch {

  class { 'project_config':
    url => $project_config_repo,
  }

  class { 'hound':
    manage_config => false,
  }

  include jeepyb
  include logrotate
  include pip

  $local_git_dir = '/var/lib/git'
  $ssh_project_key = ''

  exec { 'create-hound-config':
    command     => 'create-hound-config',
    path        => '/bin:/usr/bin:/usr/local/bin',
    environment => "PROJECTS_YAML=${::project_config::jeepyb_project_file}",
    user        => 'hound',
    cwd         => '/home/hound',
    require     => [
      User['hound'],
      $::project_config::config_dir,
    ],
    refreshonly => true,
  }

}
