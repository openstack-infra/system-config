# == Class: openstack_project::jclouds_slave
#
class openstack_project::jclouds_slave {
  include openstack_project
  include tmpreaper
  include unattended_upgrades
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [],
    certname                  => $::fqdn,
    sysadmins                 => [],
  }
  class { 'jenkins::slave':
    user => false,
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
