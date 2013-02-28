# == Class: openstack_project::automatic_upgrades
#
class openstack_project::automatic_upgrades (
) {

  if $::operatingsystem == 'Ubuntu' {
    include unattended_upgrades
  }

  #FIXME need to implement an automatic upgrades module for RHEL

}
