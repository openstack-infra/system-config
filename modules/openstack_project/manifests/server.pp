# A server that we expect to run for some time
class openstack_project::server (
  $iptables_public_tcp_ports = [],
  $sysadmins                 = [],
  $certname                  = $fqdn
) {
  class { 'openstack_project::template':
    iptables_public_tcp_ports => $iptables_public_tcp_ports,
    certname => $certname,
  }
  class { 'exim':
    sysadmin => $sysadmins
  }
}
