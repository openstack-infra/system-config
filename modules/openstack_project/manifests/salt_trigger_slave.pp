# Slave used for automatically triggering commands on the salt master.
#
# == Class: openstack_project::salt_trigger_slave
#
class openstack_project::salt_trigger_slave (
  $jenkins_ssh_public_key = ''
) {

  class { 'openstack_project::slave':
    jenkins_ssh_public_key => $jenkins_ssh_public_key,
  }

}
