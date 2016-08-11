# == Class: openstack_project::users
#
class openstack_project::users (
  $install_users = false,
  $local_users   = hiera_hash('openstack_project::users::local_users', {}),
) {
  # Make sure we have our UID/GID account minimums for dynamic users set higher
  # than we'll use for static assignments, so as to avoid future conflicts.
  include ::openstack_project::params
  file { '/etc/login.defs':
    ensure => present,
    group  => 'root',
    mode   => '0644',
    owner  => 'root',
    source => $::openstack_project::params::login_defs,
  }
  User::Virtual::Localuser {
    require => File['/etc/login.defs']
  }

  if ( $install_users ) {
    package { $::openstack_project::params::user_packages: ensure => present }
    create_resources('User::Virtual::Localuser', $local_users, { require => File['/etc/login.defs'] })
  } else {
    create_resources('user::virtual::disable', $local_users)
  }

}
