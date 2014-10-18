# Basic AFS client config
class openstack_project::afs (
  $cell = 'openstack.org',
  $sysadmins = [],
) {

  class { 'openstack_project::server':
    iptables_public_udp_ports => [7001,7002,7003,7004,7005,7006,7007],
    sysadmins                 => $sysadmins
  }

  class { 'afs::client':
    cell         => $cell,
    realm        => 'OPENSTACK.ORG',
    admin_server => 'kdc.openstack.org',
    kdcs         => [
      'kdc01.openstack.org',
      'kdc02.openstack.org',
    ],
  }

}
