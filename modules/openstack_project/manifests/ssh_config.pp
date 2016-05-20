# == Class: openstack_project::ssh_config
#
# support for custom ssh_config file
#
class openstack_project::ssh_config (
  $stricthostkeycheckservers
) {

  file { '/etc/ssh/ssh_config':
    ensure  => present,
    content => template('openstack_project/ssh_config.erb'),
    replace => true,
    owner   => 'root',
    group   => 'root',
    mode    => '0644'
  }
}