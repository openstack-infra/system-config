# == Class: test_project::automatic_upgrades
#
class test_project::automatic_upgrades (
  $origins = []
) {

  if $::osfamily == 'Debian' {
    class { 'unattended_upgrades':
      origins => $origins,
    }
  }
  if $::osfamily == 'RedHat' {
    include packagekit::cron
  }

}
