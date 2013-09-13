# Slave used for automatically triggering commands on the salt master.
#
# == Class: openstack_project::salt_trigger_slave
#
class openstack_project::salt_trigger_slave (
  $jenkins_ssh_public_key = ''
) {

  class { 'openstack_project::slave':
    ssh_key => $jenkins_ssh_public_key,
  }

  file { '/etc/sudoers.d/salt-trigger':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0440',
    source  => 'puppet:///modules/openstack_project/salt-trigger.sudoers',
    replace => true,
  }

}
