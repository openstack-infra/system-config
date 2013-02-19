# == Class: openstack_project::devstack_launch_slave
#
class openstack_project::devstack_launch_slave (
) {

  class { 'openstack_project::slave':
    bare => true,
  }

  package { ['python-novaclient', 'statsd', 'paramiko']:
    ensure   => latest,
    provider => pip,
    require  => Class['pip'],
  }
}
