# AFS Fileserver/BOS
class openstack_project::afsfs (
  $cell                      = 'openstack.org',
  $sysadmins                 = [],
  $iptables_public_udp_ports = [
    7000,
    7002,
    7003,
    7004,
    7005,
    7006,
    7007,
  ],
  $dbservers                 = [
    {
      name     => 'afsdb01.openstack.org',
      ip       => '104.130.136.20',
    },
    {
      name     => 'afsdb02.openstack.org',
      ip       => '23.253.200.228',
    },
  ]
) {

  class { 'openstack_project::server':
    iptables_public_udp_ports => $iptables_public_udp_ports,
    sysadmins                 => $sysadmins,
    afs                       => true,
  }

  class { 'openafs::fileserver':
    cell         => $cell,
    dbservers    => $dbservers,
    require      => Class['Openstack_project::Server'],
  }
}
