class openstack_project::owncloud (

) {
  class {'openstack_project::server':
    iptables_public_tcp_ports => [80],
    sysadmins                 => $sysadmins,
  }
  include owncloud

  owncloud::site {'owncloud':

  }
}
