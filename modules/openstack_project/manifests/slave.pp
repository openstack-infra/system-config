# == Class: openstack_project::slave
#
class openstack_project::slave (
  $certname = $::fqdn,
  $sysadmins = []
) {
  include openstack_project
  include tmpreaper
  include unattended_upgrades
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [],
    certname                  => $certname,
    sysadmins                 => $sysadmins,
  }
  class { 'jenkins::slave':
    ssh_key => $openstack_project::jenkins_ssh_key,
  }
  class { 'salt':
    salt_master => 'ci-puppetmaster.openstack.org',
  }
}
