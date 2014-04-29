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

  file { "${title}_sshdir":
    ensure  => directory,
    name    => "${home}/.ssh",
    owner   => $title,
    group   => $title,
    mode    => '0700',
    require => User[$title],
  }

  file { "${title}_keyfile":
    ensure  => present,
    mode    => '0600',
    name    => "${home}/.ssh/authorized_keys",
    require => File["${title}_sshdir"],
  }

  ssh_authorized_key { $key_id:
    ensure  => present,
    key     => $sshkeys,
    user    => $title,
    type    => 'ssh-rsa',
    require => File["${title}_keyfile"],
  }

  ssh_authorized_key { "${title}_keys":
    ensure => absent,
    user   => $title,
  }

  if ( $old_keys != [] ) {
    ssh_authorized_key { $old_keys:
      ensure => absent,
      user   => $title,
    }
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
