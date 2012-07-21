class openstack_project::jenkins_slave {
  include tmpreaper
  include apt::unattended-upgrades
  class { 'openstack_server':
    iptables_public_tcp_ports => []
  }
  class { 'jenkins_slave':
    ssh_key => $openstack_project::jenkins_ssh_key
  }
}


