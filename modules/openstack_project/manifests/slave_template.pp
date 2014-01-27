# == Class: openstack_project::slave_template
#
class openstack_project::slave_template (
  $install_users = true,
  $ssh_key = $openstack_project::jenkins_ssh_key
) inherits openstack_project {
  class { 'openstack_project::template':
    # Port 8000 to allow nova servers to reach heat-api-cfn
    iptables_public_tcp_ports => [8000],
    install_users             => $install_users,
  }
  class { 'jenkins::slave':
    ssh_key => $ssh_key,
    sudo    => true,
    bare    => true,
  }
}
