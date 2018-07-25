# == Class: openstack_project::server
#
# A server that we expect to run for some time
class openstack_project::server (
  $iptables_public_tcp_ports = [],
  $iptables_public_udp_ports = [],
  $iptables_rules4           = [],
  $iptables_rules6           = [],
  $iptables_allowed_hosts    = [],
  $pin_puppet                = '3.',
  $ca_server                 = undef,
  $enable_unbound            = true,
  $afs                       = false,
  $afs_cache_size            = 500000,
  $pypi_index_url            = 'https://pypi.python.org/simple',
) {

  class { 'timezone':
    timezone => 'Etc/UTC',
  }

  # Include ::apt while we work on the puppet->ansible transition
  if ($::osfamily == 'Debian') {
    include ::apt
  }

  ###########################################################
  # Manage  ntp

  include '::ntp'

  ###########################################################
  # Manage Root ssh

  class { 'ssh':
    trusted_ssh_type   => 'address',
    trusted_ssh_source => '23.253.245.198,2001:4800:7818:101:3c21:a454:23ed:4072,23.253.234.219,2001:4800:7817:103:be76:4eff:fe04:5a1d',
  }

  ###########################################################
  # Process if ( $high_level_directive ) blocks

  if ($enable_unbound) {
    class { 'unbound':
      install_resolv_conf => $install_resolv_conf
    }
  }

  if $afs {
    class { 'openafs::client':
      cell         => 'openstack.org',
      realm        => 'OPENSTACK.ORG',
      admin_server => 'kdc.openstack.org',
      cache_size   => $afs_cache_size,
      kdcs         => [
        'kdc01.openstack.org',
        'kdc04.openstack.org',
      ],
    }
    $all_udp = concat(
      $iptables_public_udp_ports, [7001])
  } else {
    $all_udp = $iptables_public_udp_ports
  }

  class { 'openstack_project::automatic_upgrades':
    origins => ["Puppetlabs:${lsbdistcodename}"],
  }

  include snmpd

  $snmp_v4hosts = [
    '172.99.116.215', # cacti02.openstack.org
  ]
  $snmp_v6hosts = [
    '2001:4800:7821:105:be76:4eff:fe04:b9a5', # cacti02.opentsack.org
  ]
  class { 'iptables':
    public_tcp_ports => $iptables_public_tcp_ports,
    public_udp_ports => $all_udp,
    rules4           => $iptables_rules4,
    rules6           => $iptables_rules6,
    snmp_v4hosts     => $snmp_v4hosts,
    snmp_v6hosts     => $snmp_v6hosts,
    allowed_hosts    => $iptables_allowed_hosts,
  }

}
