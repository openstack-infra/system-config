# == Class: openstack_project::dotfiles
#
define openstack_project::dotfiles(
  $email,
  $realname,
) {
  include ::git

  if ($::environment != 'production') {
    git::config { 'user.name':
      value   => $realname,
      user    => $title,
    }
    git::config { 'user.email':
      value   => $email,
      user    => $title,
    }
  }
}
