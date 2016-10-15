# == Class: openstack_project::zuul_launcher
#
class openstack_project::zuul_launcher(
  $project_config_repo = '',
  $project_config_revision = 'master',
  $project_config_base = '',
  $zuul_launcher_keytab = '',
) {

  if ! defined(Class['project_config']) {
    class { '::project_config':
      url  => $project_config_repo,
      base => $project_config_base,
    }
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

  if ! defined(Class['known_hosts']) {
    file { '/home/zuul/.ssh':
      ensure  => directory,
      owner   => 'zuul',
      group   => 'zuul',
      mode    => '0700',
      require => User['zuul'],
    }
  }

  file { '/home/zuul/.ssh/config':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/zuul/launcher_ssh_config',
    owner   => 'zuul',
    group   => 'zuul',
    require => File['/home/zuul/.ssh'],
  }

  class { 'zuul::launcher': }
}
