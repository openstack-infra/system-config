# == Class: openstack_project::wheel_mirror
#
class openstack_project::wheel_mirror (
  $data_directory = '/srv/static/wheel',
) {

  # The wheel mirror is a directory of python wheels, which have been rsynced'
  # from the wheel build slaves.
  file { "${data_directory}":
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
  }
}
