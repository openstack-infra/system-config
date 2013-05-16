# == Class: openstack_project::automatic_upgrades
#
class openstack_project::automatic_upgrades (
) {

  if $::osfamily == 'Debian' {
    include unattended_upgrades
  }
  if $::osfamily == 'RedHat' {
    include packagekit::cron
  }

}
