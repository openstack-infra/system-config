# == Class: pypimorror
#
class pypimirror(
  $vhost_name = $::fqdn,
  $log_filename = '/var/log/pypimirror.log',
  $mirror_file_path = '/var/lib/pypimirror',
  $pip_download = '/var/lib/pip-download',
  $pip_cache = '/var/cache/pip',
  $git_source = 'https://github.com',
  $local_git_dir = '/var/lib/git',
  $ssh_project_key = 'UNDEF',
  $projects = []
) {

  include apache
  include pip
  include remove_nginx
  include jeepyb

  package { 'python-yaml':
    ensure => present,
  }

  file { '/usr/local/mirror_scripts':
    ensure => directory,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  }

  file { $pip_download:
    ensure => directory,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  }

  file { $pip_cache:
    ensure => directory,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  }

  file { '/etc/openstackci':
    ensure => directory,
    owner  => 'root',
  }

  file { '/etc/openstackci/projects.yaml':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('openstack_project/review.projects.yaml.erb'),
    replace => true,
  }

  file { '/usr/local/mirror_scripts/run-mirror.sh':
    ensure  => present,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    content => template('pypimirror/run-mirror.sh.erb'),
    require => [
      File['/usr/local/mirror_scripts'],
      Class[pip],
    ],
  }

  file { '/usr/local/mirror_scripts/run_mirror.py':
    ensure  => absent,
  }

  file { '/usr/local/mirror_scripts/pull-repo.sh':
    ensure  => absent,
  }

  file { '/usr/local/mirror_scripts/process_cache.py':
    ensure  => absent,
  }

  # Add cron job to update the mirror

  cron { 'update_mirror':
    user    => 'root',
    minute  => '0',
    command => '/usr/local/mirror_scripts/run-mirror.sh',
    require => File['/usr/local/mirror_scripts/run-mirror.sh'],
  }

  # Rotate the mirror log file

  include logrotate
  logrotate::file { 'pypimirror':
    log     => $log_filename,
    options => [
      'compress',
      'delaycompress',
      'missingok',
      'rotate 7',
      'daily',
      'notifempty',
    ],
    require => Cron['update_mirror'],
  }

  apache::vhost { $vhost_name:
    port     => 80,
    docroot  => $mirror_file_path,
    priority => 50,
  }
}
