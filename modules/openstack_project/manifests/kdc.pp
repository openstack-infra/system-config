# kerberos kdc servers
class openstack_project::kdc (
  $slave = false,
  $sysadmins = [],
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [88,464,749,754],
    iptables_public_udp_ports => [88,464,749],
    sysadmins                 => $sysadmins
  }
  class { 'kerberos::server':
    realm        => 'OPENSTACK.ORG',
    kdcs         => [
      'kdc01.openstack.org',
      'kdc02.openstack.org',
    ],
    admin_server => 'kdc.openstack.org',
    slaves       => [
      'kdc02.openstack.org',
    ],
    slave        => $slave,
  }
}
