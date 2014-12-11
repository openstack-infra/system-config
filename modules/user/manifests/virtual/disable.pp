# used to remove a user
# example:
#   user::virtual::disable { 'baduser': }

define user::virtual::disable(
) {
  $username = $title
  #1. Remove user
  user { "${username}":
    ensure => absent,
  }
  #2. remove sshkeys file(s)
  file { "rm_authorized_keys_${username}":
    ensure  => absent,
    path    => "/home/${username}/.ssh/authorized_keys",
  }
  file { "rm_authorized_keys2_${username}":
    ensure  => absent,
    path    => "/home/${username}/.ssh/authorized_keys2",
  }
  #3. rm screen dir (just in case)
  file { "rm_screen_${username}":
    ensure => absent,
    path => "/var/run/screen/S-${username}",
    recurse => true,
    purge => true,
    force => true,
  }
}

