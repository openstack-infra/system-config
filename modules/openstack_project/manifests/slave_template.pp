class openstack_project::slave_template {
  class { 'openstack_project::template':
    iptables_public_tcp_ports => []
  }
  class { 'jenkins_slave':
    ssh_key => $openstack_project::jenkins_ssh_key,
    sudo => true,
    bare => true
  }
}
