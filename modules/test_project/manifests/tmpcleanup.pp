# == Class: test_project::tmpcleanup
#
class test_project::tmpcleanup (
) {

  if $::osfamily == 'Debian' {
    include tmpreaper
  }

  # FIXME need to implement an something on RHEL to fine tune the
  # temp directory cleanup.

}
