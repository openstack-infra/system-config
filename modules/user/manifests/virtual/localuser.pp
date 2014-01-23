# usage
#
# user::virtual::localuser['username']

define user::virtual::localuser(
  $realname,
  $groups     = [ 'sudo', 'admin', ],
  $sshkeys    = '',
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

  file { "${title}_keys":
    ensure  => present,
    content => $sshkeys,
    group   => $title,
    mode    => '0400',
    name    => "${home}/.ssh/authorized_keys",
    owner   => $title,
    require => File["${title}_sshdir"],
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
