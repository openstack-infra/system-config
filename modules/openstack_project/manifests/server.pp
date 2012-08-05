# A server that we expect to run for some time
class openstack_project::server (
  $iptables_public_tcp_ports = [],
  $certname=$fqdn
  ) {
  include openstack_project
  class { 'openstack_project::template':
    iptables_public_tcp_ports => $iptables_public_tcp_ports,
    certname => $certname,
  }
  class { 'exim':
    sysadmin => $openstack_project::sysadmins
  }
}
