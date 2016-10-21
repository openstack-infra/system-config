# == Class: openstack_project::pholio
#

class openstack_project::pholio (
  $sysadmins = []
) {

  include ::phabricator

}
