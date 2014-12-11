# Class: openstack_project::users_install
#
# This class handles adding and removing openstack admin users
# from the servers.
#
# Parameters:
#   install_users - Boolean to set install or removal of O.O
#   admins.  Defaults to 'false', can be set in hiera.
#
# Requires:
#   openstack_project::users - must contain the users designated.
#
# Sample Usage:
#   include openstack_project::users_install
#   class { 'openstack_project::users_install':
#     install_users => true,
#   }

class openstack_project::users_install (
  $admin_users = [
    'mordred',
    'corvus',
    'clarkb',
    'fungi',
    'slukjanov',
  ],
  $admin_users_disable = {
    'mordred' => {},
    'corvus' => {},
    'clarkb' => {},
    'fungi' => {},
    'slukjanov' => {},
  },
  $install_users = false,
) {

  include openstack_project::users

  ## TODO: this should be it's own manifest.
  if ( $install_users == true ) {
    package { $::openstack_project::params::user_packages:
      ensure => present
    }
    realize (
      User::Virtual::Localuser[$admin_users],
    )
  } else {
    create_resources(User::Virtual::Disable,$admin_users_disable)
  }
}
