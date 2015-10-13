# == Class: openstack_project::tmpcleanup
#
class openstack_project::tmpcleanup (
) {

  if $::osfamily == 'Debian' {
    include tmpreaper
  }

  # FIXME need to implement an something on RHEL to fine tune the
  # temp directory cleanup.

}
