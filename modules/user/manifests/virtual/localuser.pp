# usage
#
# user::virtual::localuser['username']

define user::virtual::localuser(
  $realname,
  $groups     = [ 'sudo', 'admin', ],
  $sshkeys    = '',
  $key_id     = '',
  $old_keys   = [],
  $shell      = '/bin/bash',
  $home       = "/home/${title}",
  $managehome = true
) {

  group { $title:
    ensure => present,
  }

  user { $title:
    ensure     => present,
    comment    => $realname,
    gid        => $title,
    groups     => $groups,
    home       => $home,
    managehome => $managehome,
    membership => 'minimum',
    shell      => $shell,
    require    => Group[$title],
  }

  ssh_authorized_key { $key_id:
    ensure  => present,
    key     => $sshkeys,
    user    => $title,
    type    => 'ssh-rsa',
  }

  if ( $old_keys != [] ) {
    ssh_authorized_key { $old_keys:
      ensure => absent,
      user   => $title,
    }
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
