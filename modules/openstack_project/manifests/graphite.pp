# Class to configure graphite on a node.
class openstack_project::graphite (
  $sysadmins = [],
  $graphite_admin_user = '',
  $graphite_admin_email = '',
  $graphite_admin_password ='',
) {

  class { '::graphite':
    graphite_admin_user     => $graphite_admin_user,
    graphite_admin_email    => $graphite_admin_email,
    graphite_admin_password => $graphite_admin_password,
  }
}
