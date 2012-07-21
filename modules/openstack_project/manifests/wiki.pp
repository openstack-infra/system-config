class openstack_project::wiki {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443]
  }

  realize (
    User::Virtual::Localuser["rlane"],
  )
}
