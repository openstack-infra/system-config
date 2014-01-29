# == Class: openstack_project::slave_template
#
class openstack_project::slave_template (
  $install_users = true,
  $ssh_key = $openstack_project::jenkins_ssh_key
) inherits openstack_project {
  class { 'openstack_project::template':
    # Port 8000 from the devstack neutron public net to allow
    # nova servers to reach heat-api-cfn
    iptables_rules4           =>
      ['-p tcp --dport 8000 -s 172.24.4.0/24 -j ACCEPT'],
    iptables_public_tcp_ports => [],
    install_users             => $install_users,
  }
  class { 'jenkins::slave':
    ssh_key => $ssh_key,
    sudo    => true,
    bare    => true,
  }
}
