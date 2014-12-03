# kerberos kdc servers
class openstack_project::kdc (
  $kerberos_realm = 'OPENSTACK.ORG',
  $kdc_admin_server = 'kdc.openstack.org',
  $kdc_servers = [
      'kdc01.openstack.org',
      'kdc02.openstack.org',
  ],
  $kdc_slave_servers = [
      'kdc02.openstack.org',
  ],
  $slave = false,
  $sysadmins = [],
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [88,464,749,754],
    iptables_public_udp_ports => [88,464,749],
    sysadmins                 => $sysadmins
  }
  class { 'kerberos::server':
    realm        => $kerberos_realm,
    kdcs         => $kdc_servers,
    admin_server => $kdc_admin_server,
    slaves       => $kdc_slave_servers,
    slave        => $slave,
  }
}
