class openstack_project::slave {
  include openstack_project
  include tmpreaper
  include unattended_upgrades
  class { 'openstack_project::server':
    iptables_public_tcp_ports => []
  }
  class { 'jenkins_slave':
    ssh_key => $openstack_project::jenkins_ssh_key
  }
}


