class openstack_project::pypi {
  include tmpreaper
  include unattended_upgrades
  include openstack_project

  # include jenkins slave so that build deps are there for the pip download
  class { 'jenkins_slave':
    ssh_key => "",
    user => false
  }

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80]
  }

  class { "pypimirror":
    projects => $openstack_project::project_list,
  }
}
