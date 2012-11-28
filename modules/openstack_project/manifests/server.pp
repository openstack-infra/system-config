# == Class: openstack_project::server
#
# A server that we expect to run for some time
class openstack_project::server (
  $iptables_public_tcp_ports = [],
  $iptables_rules            = [],
  $sysadmins                 = [],
  $certname                  = $::fqdn
) {
  class { 'openstack_project::template':
    iptables_public_tcp_ports => $iptables_public_tcp_ports,
    iptables_rules            => $iptables_rules,
    certname                  => $certname,
  }
  class { 'exim':
    sysadmin => $sysadmins,
  }
}
