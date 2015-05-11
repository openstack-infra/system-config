# == Class: openstack_project::mirror
# Controls syncing and serving of various FOSS mirrors
#
class openstack_project::mirror(
  $vhost_name = $::fqdn,
) {

  # imports
  include apache

  # setup dir structure
  ensure_resource('file', '/srv/static', {
    'ensure' => 'directory',
  })

  ensure_resource('file', '/srv/static/mirror', {
    'ensure'  => 'directory',
    'owner'   => 'root',
    'group'   => 'root',
  })

  # one vhost to rule them all
  apache::vhost { $vhost_name:
    port     => 80,
    priority => '50',
    docroot  => '/srv/static/mirror',
    require  => [Class['openstack_project::pypi_mirror'], Class['openstack_project::rubygems_mirror']],
  }

  # List of things to mirror
  include openstack_project::pypi_mirror
  include openstack_project::rubygems_mirror

}
