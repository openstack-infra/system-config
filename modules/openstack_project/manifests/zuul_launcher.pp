# == Class: openstack_project::zuul_launcher
#
class openstack_project::zuul_launcher(
  $vhost_name = $::fqdn,
  $gearman_server = '127.0.0.1',
  $gerrit_server = '',
  $gerrit_user = '',
  $gerrit_ssh_host_key = '',
  $zuul_ssh_private_key = '',
  $zuul_url = '',
  $statsd_host = '',
  $project_config_repo = '',
  $project_config_base = '',
  $git_email = 'jenkins@openstack.org',
  $git_name = 'OpenStack Jenkins',
  $workspace_root = '/home/jenkins/workspace',
  $worker_private_key_file = '/var/lib/zuul/ssh/id_rsa',
  $worker_username = 'jenkins',
  $sites = [],
  $nodes = [],
  $accept_nodes = '',
  $zuul_launcher_keytab = '',
) {

  class { '::project_config':
    url  => $project_config_repo,
    base => $project_config_base,
  }

  file { '/etc/zuul-launcher.keytab':
    owner   => 'zuul',
    group   => 'zuul',
    mode    => '0400',
    content => $zuul_launcher_keytab,
  }

  file { '/etc/jenkins_jobs':
    ensure => directory,
  }

  file { '/etc/jenkins_jobs/config':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    recurse => true,
    purge   => true,
    force   => true,
    source  => $::project_config::jenkins_job_builder_config_dir,
    require => [File['/etc/jenkins_jobs'],
                $::project_config::config_dir],
    notify  => Exec['zuul-launcher-reload'],
  }

  file { '/home/zuul/.ssh':
    ensure  => directory,
    owner   => 'zuul',
    group   => 'zuul',
    mode    => '0700',
    require => User['zuul'],
  }

  file { '/home/zuul/.ssh/config':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/zuul/launcher_ssh_config',
    owner   => 'zuul',
    group   => 'zuul',
    require => File['/home/zuul/.ssh'],
  }

  class { '::zuul':
    vhost_name              => $vhost_name,
    gearman_server          => $gearman_server,
    gerrit_server           => $gerrit_server,
    gerrit_user             => $gerrit_user,
    zuul_ssh_private_key    => $zuul_ssh_private_key,
    zuul_url                => $zuul_url,
    git_email               => $git_email,
    git_name                => $git_name,
    revision                => $revision,
    git_source_repo         => $git_source_repo,
    jenkins_jobs            => '/etc/jenkins_jobs/config',
    workspace_root          => $workspace_root,
    worker_private_key_file => $worker_private_key_file,
    worker_username         => $worker_username,
    sites                   => $sites,
    nodes                   => $nodes,
    accept_nodes            => $accept_nodes,
  }

  class { 'zuul::launcher': }
}
