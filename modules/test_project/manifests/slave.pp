# == Class: test_project::slave
#
class test_project::slave (
  $thin = false,
  $certname = $::fqdn,
  $ssh_key = '',
  $sysadmins = [],
  $jenkins_gitfullname = 'OpenStack Jenkins',
  $jenkins_gitemail = 'jenkins@openstack.org',
  $project_config_repo = 'https://git.openstack.org/openstack-infra/project-config',
) {

  include test_project
  include test_project::tmpcleanup

  class { 'test_project::server':
    iptables_public_tcp_ports => [],
    iptables_public_udp_ports => [],
    certname                  => $certname,
    sysadmins                 => $sysadmins,
  }

  class { 'jenkins::slave':
    ssh_key      => $ssh_key,
    gitfullname  => $jenkins_gitfullname,
    gitemail     => $jenkins_gitemail,
  }

  include jenkins::cgroups
  include ulimit
  ulimit::conf { 'limit_jenkins_procs':
    limit_domain => 'jenkins',
    limit_type   => 'hard',
    limit_item   => 'nproc',
    limit_value  => '256'
  }

  class { 'test_project::slave_common':
    project_config_repo => $project_config_repo,
  }

  if (! $thin) {
    include test_project::thick_slave
  }

}
