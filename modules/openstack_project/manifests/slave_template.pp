class openstack_project::slave_template inherits openstack_project(
  $install_users=true,
  $ssh_key=$openstack_project::jenkins_ssh_key
) {
  class { 'openstack_project::template':
    iptables_public_tcp_ports => [],
    install_users => $install_users,
  }
  class { 'jenkins::slave':
    ssh_key => $ssh_key,
    sudo => true,
    bare => true
  }
}
