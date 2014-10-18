# kerberos kdc servers

class openstack_project::afsdb (
  $sysadmins = [],
) {
  class { 'openstack_project::server':
    iptables_public_udp_ports => [7003,7003,7005],
    sysadmins                 => $sysadmins
  }
  class { 'afs::dbserver':
    realm        => 'OPENSTACK.ORG',
    kdcs         => [
      'kdc01.openstack.org',
      'kdc02.openstack.org',
    ],
    admin_server => 'kdc.openstack.org',
  }
}
