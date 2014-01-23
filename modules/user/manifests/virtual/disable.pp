# used to remove a user
# example:
#   user::virtual::disable { 'baduser': }

define user::virtual::disable(
) {
  $username = $title
  #1. Remove user
  exec { "disable_${username}":
    command => "userdel ${username}",
    onlyif  => "grep ^${username}: /etc/passwd",
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
  exec { "rm_screen_${username}":
    command => "rm -rf /var/run/screen/S-${username}",
    onlyif  => "ls /var/run/screen/S-${username}",
  }
}

