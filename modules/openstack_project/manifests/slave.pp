# == Class: openstack_project::slave
#
class openstack_project::slave (
  $bare = false,
  $certname = $::fqdn,
  $ssh_key = '',
  $sysadmins = []
) {
  include openstack_project
  include openstack_project::tmpcleanup
  include openstack_project::automatic_upgrades
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [],
    certname                  => $certname,
    sysadmins                 => $sysadmins,
  }
  class { 'jenkins::slave':
    bare    => $bare,
    ssh_key => $ssh_key,
  }
  class { 'salt':
    salt_master => 'ci-puppetmaster.openstack.org',
  }
  include jenkins::cgroups
  include ulimit
  ulimit::conf { 'limit_jenkins_procs':
    limit_domain => 'jenkins',
    limit_type   => 'hard',
    limit_item   => 'nproc',
    limit_value  => '256'
  }
}
