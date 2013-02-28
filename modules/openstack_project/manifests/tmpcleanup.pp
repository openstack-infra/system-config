# == Class: openstack_project::tmpcleanup
#
class openstack_project::tmpcleanup (
) {

  if $::operatingsystem == 'Ubuntu' {
    include tmpreaper
  }

  # FIXME need to implement an something on RHEL to fine tune the
  # temp directory cleanup.

}
