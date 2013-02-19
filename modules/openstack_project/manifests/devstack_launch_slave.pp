# == Class: openstack_project::devstack_launch_slave
#
class openstack_project::devstack_launch_slave (
) {

  include openstack_project::slave

  package { ['python-novaclient', 'statsd']:
    ensure   => latest,
    provider => pip,
    require  => Class['pip'],
  }
}
