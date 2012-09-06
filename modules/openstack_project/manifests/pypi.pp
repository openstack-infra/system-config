class openstack_project::pypi (
  $sysadmins = []
) {
  include tmpreaper
  include unattended_upgrades

  # include jenkins slave so that build deps are there for the pip download
  class { 'jenkins::slave':
    ssh_key => "",
    user => false
  }

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
    sysadmins => $sysadmins
  }

  class { "pypimirror":
    projects => $openstack_project::project_list,
  }
}
