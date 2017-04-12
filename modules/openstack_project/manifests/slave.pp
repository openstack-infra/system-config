# == Class: openstack_project::slave
#
class openstack_project::slave (
  $thin = false,
  $certname = $::fqdn,
  $ssh_key = '',
  $sysadmins = [],
  $jenkins_gitfullname = 'OpenStack Jenkins',
  $jenkins_gitemail = 'jenkins@openstack.org',
  $jenkins_gitpgpkey = 'jenkins@openstack.org',
  $jenkins_gerrituser = 'jenkins',
  $jenkins_gerritkey = undef,
  $project_config_repo = 'https://git.openstack.org/openstack-infra/project-config',
  $afs = false,
) {

  include openstack_project
  include openstack_project::tmpcleanup

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [19885],
    iptables_public_udp_ports => [],
    certname                  => $certname,
    sysadmins                 => $sysadmins,
    afs                       => $afs
  }

  class { 'jenkins::slave':
    ssh_key      => $ssh_key,
    gitfullname  => $jenkins_gitfullname,
    gitemail     => $jenkins_gitemail,
    gitpgpkey    => $jenkins_gitpgpkey,
    gerrituser   => $jenkins_gerrituser,
    gerritkey    => $jenkins_gerritkey,
  }

  include jenkins::cgroups
  include ulimit
  ulimit::conf { 'limit_jenkins_procs':
    limit_domain => 'jenkins',
    limit_type   => 'hard',
    limit_item   => 'nproc',
    limit_value  => '256'
  }

  class { 'project_config':
    url  => $project_config_repo,
  }

  file { '/usr/local/jenkins/common_data':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    recurse => true,
    purge   => true,
    force   => true,
    require => [File['/usr/local/jenkins'],
                $::project_config::config_dir],
    source  => $::project_config::jenkins_data_dir,
  }

  file { '/usr/local/jenkins/slave_scripts':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    recurse => true,
    purge   => true,
    force   => true,
    require => [File['/usr/local/jenkins'],
                $::project_config::config_dir],
    source  => $::project_config::jenkins_scripts_dir,
  }

  class { 'openstack_project::slave_common': }

  if (! $thin) {
    include openstack_project::thick_slave
  }

}
