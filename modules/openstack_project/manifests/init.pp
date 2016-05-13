# == Class: openstack_project
#
class openstack_project {

  $jenkins_ssh_key = hiera('jenkins_ssh_key')

  $jenkins_dev_ssh_key = hiera('jenkins_ssh_key')

}
