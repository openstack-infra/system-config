# kerberos kdc servers

class openstack_project::eavesdrop (
  $slave = false,
  $sysadmins = [],
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [749],
    iptables_public_tcp_ports => [88,464],
    sysadmins                 => $sysadmins
  }
  class { 'kerberos::server':
    realm        => 'OPENSTACK.ORG',
    kdcs         => [
      'kdc01.openstack.org',
      'kdc02.openstack.org',
    ],
    admin_server => 'kdc.openstack.org',
    slave        => $slave,
  }
}
