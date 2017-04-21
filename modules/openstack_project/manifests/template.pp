# == Class: openstack_project::template
#
# A template host with no running services
#
class openstack_project::template (
  $iptables_public_tcp_ports = [],
  $iptables_public_udp_ports = [],
  $iptables_rules4           = [],
  $iptables_rules6           = [],
  $snmp_v4hosts              = [],
  $snmp_v6hosts              = [],
  $pin_puppet                = '3.',
  $install_resolv_conf       = true,
  $certname                  = $::fqdn,
  $ca_server                 = undef,
  $afs                       = false,
  $afs_cache_size            = 500000,
  $puppetmaster_server       = 'puppetmaster.openstack.org',
  $sysadmins                 = [],
  $permit_root_login         = 'no',
) {

  ###########################################################
  # Classes for all hosts

  if ( $afs ) {
    $all_udp = concat(
      $iptables_public_udp_ports, [7001])
  } else {
    $all_udp = $iptables_public_udp_ports
  }

  class { 'iptables':
    public_tcp_ports => $iptables_public_tcp_ports,
    public_udp_ports => $all_udp,
    rules4           => $iptables_rules4,
    rules6           => $iptables_rules6,
    snmp_v4hosts     => $snmp_v4hosts,
    snmp_v6hosts     => $snmp_v6hosts,
  }

  if ($::osfamily == 'Debian') {
    # NOTE(pabelanger): Puppetlabs only support Ubuntu Trusty and below,
    # anything greater will use the OS version of puppet.
    if ($::operatingsystemrelease < '15.04') {
      include ::apt
      apt::source { 'puppetlabs':
        location => 'http://apt.puppetlabs.com',
        repos    => 'main',
        key      => {
          'id'     =>'47B320EB4C7C375AA9DAE1A01054B7A24BD6EC30',
          'server' => 'pgp.mit.edu',
        },
      }
    }
  }

  if ($::operatingsystem == 'CentOS') {
    file { '/etc/yum.repos.d/puppetlabs.repo':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      source  => 'puppet:///modules/openstack_project/centos7-puppetlabs.repo',
      replace => true,
    }
  }

  ###########################################################

}
