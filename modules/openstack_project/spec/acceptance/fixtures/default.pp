$iptables_rules = ['-p tcp --syn --dport 29418 -m connlimit --connlimit-above 100 -j REJECT']
class { 'openstack_project::server':
  iptables_public_tcp_ports => [80, 443, 29418],
  iptables_rules6           => $iptables_rules,
  iptables_rules4           => $iptables_rules,
  afs                       => true,
}
