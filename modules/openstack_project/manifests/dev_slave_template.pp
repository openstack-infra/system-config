# == Class: openstack_project::dev_slave_template
#
class openstack_project::dev_slave_template (
  $install_users = true,
  $ssh_key = $openstack_project::jenkins_dev_ssh_key
) inherits openstack_project {
  class { 'openstack_project::template':
    iptables_public_tcp_ports => [],
    install_users             => $install_users,
  }
  class { 'jenkins::slave':
    ssh_key => $ssh_key,
    sudo    => true,
    bare    => true,
  }
}
