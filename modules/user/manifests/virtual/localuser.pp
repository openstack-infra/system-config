define user::virtual::localuser(
  $realname,
  $sshkeys = '',
  $shell = '/bin/bash'
) {
  group { $title:
    ensure => present,
  }

  user { $title:
    ensure     => present,
    comment    => $realname,
    gid        => $title,
    groups     => [
      'sudo',
      'admin',
    ],
    home       => "/home/${title}",
    managehome => true,  # creates home directory, does not manage it
    membership => 'minimum',
    require    => Group[$title],
    shell      => $shell,
  }

  file { "${title}_sshdir":
    ensure  => directory,
    name    => "/home/${title}/.ssh",
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
    name    => "/home/${title}/.ssh/authorized_keys",
    owner   => $title,
    require => File["${title}_sshdir"],
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
