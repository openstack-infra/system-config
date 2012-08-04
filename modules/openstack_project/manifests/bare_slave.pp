# bare-bones slaves spun up by jclouds. Specifically need to not set ssh
# login limits, because it screws up jclouds provisioning
class openstack_project::bare_slave($install_users=true) {
  class { 'openstack_project::base':
    install_users => $install_users
  }

  class { 'jenkins::slave':
    ssh_key => "",
    user => false
  }
}
