# == Class: openstack_project::planet
#
class openstack_project::planet (
) {
  class { 'openstack_project::server': }
  include ::planet

  planet::site { 'openstack':
    git_url => 'git://git.openstack.org/openstack/openstack-planet',
  }
}
