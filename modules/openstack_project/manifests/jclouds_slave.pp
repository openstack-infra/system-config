# bare-bones slaves spun up by jclouds. Specifically need to not set ssh
# login limits, because it screws up jclouds provisioning
class openstack_project::jclouds_slave {
  include openstack_project::base

  class { 'jenkins_slave':
    ssh_key => "",
    user => false
  }
}
