# Class to configure hound on a node.
class openstack_project::codesearch (
  $project_config_repo,
) {

  class { 'project_config':
    url => $project_config_repo,
  }

  class { 'hound':
    manage_config => false,
  }

  include ::jeepyb
  include ::logrotate
  include ::pip

  file { '/home/hound/config.json':
    ensure => 'present',
  }

  file { '/usr/local/bin/resync-hound-config':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/openstack_project/resync-hound-config.sh',
  }

  # Note: we could trigger this from project-config changes, but it
  # does bring the service down for several minutes if something
  # changes.  Once a day should be enough.
  cron { 'hound':
    user        => root,
    hour        => '4',
    minute      => '0',
    command     => 'flock -n /var/run/hound.sync.lock resync-hound-config >> /var/log/hound.sync.log 2>&1',
    environment => [
      'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
      "PROJECTS_YAML=${::project_config::jeepyb_project_file}",
    ],
    require     => [
       File['/usr/local/bin/resync-hound-config'],
       File['/home/hound/config.json'],
    ],
  }

  logrotate::file { 'hound-sync':
    log => '/var/log/hound.sync.log',
    options => [
      'compress',
      'copytruncate',
      'missingok',
      'rotate 7',
      'daily',
      'notifempty',
    ],
  }

}
