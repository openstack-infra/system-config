# A template host with no running services
class openstack_project::template (
  $iptables_public_tcp_ports,
  $install_users = true,
  $certname = $fqdn
  ) {
  include ssh
  include snmpd
  include unattended_upgrades
  
  class { 'iptables':
    public_tcp_ports => $iptables_public_tcp_ports,
  }

  class { 'ntp::server': }

  class { 'openstack_project::base':
    install_users => $install_users,
    certname => $certname,
  }
}
