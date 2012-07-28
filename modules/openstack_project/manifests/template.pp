# A template host with no running services
class openstack_project::template ($iptables_public_tcp_ports) {
  include openstack_project::base
  include ntp
  include ssh
  include snmpd
  include apt::unattended-upgrades
  
  class { 'iptables':
    public_tcp_ports => $iptables_public_tcp_ports,
  }
}
