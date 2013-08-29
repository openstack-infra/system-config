# == Class: testcabal_project::automatic_upgrades
#
class testcabal_project::automatic_upgrades (
) {

  if $::osfamily == 'Debian' {
    include unattended_upgrades
  }
  if $::osfamily == 'RedHat' {
    include packagekit::cron
  }

}
