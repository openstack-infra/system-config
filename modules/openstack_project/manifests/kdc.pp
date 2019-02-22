# kerberos kdc servers
class openstack_project::kdc (
  $slave = false,
) {
  class { 'kerberos::server':
    realm        => 'OPENSTACK.ORG',
    kdcs         => [
      'kdc03.openstack.org',
      'kdc04.openstack.org',
    ],
    admin_server => 'kdc.openstack.org',
    slaves       => [
      'kdc04.openstack.org',
    ],
    slave        => $slave,
  }
}
