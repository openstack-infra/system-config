class openstack_project::puppetdb (
  $sysadmins = undef,
){

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [4505, 4506, 8080, 8081],
    sysadmins                 => $sysadmins,
  }

}
