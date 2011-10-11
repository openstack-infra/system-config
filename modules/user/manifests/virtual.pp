class user::virtual {
  define localuser ($realname,$sshkeys='',$shell="/bin/bash") {
    group { $title:
      ensure => 'present'
    }

    user { $title:
      ensure  => "present",
      comment => $realname,
      home    => "/home/$title",
      shell   => $shell,
      gid     => $title,
      groups  => ['sudo','admin'],
      membership => 'minimum',
      managehome => true,  # creates the home directory (does not actually manage it)
      require => Group[$title],
    }
    
    file { "${title}_sshdir":
      name => "/home/$title/.ssh",
      owner => $title,
      group => $title,
      mode => 700,
      ensure => 'directory',
      require => User[$title],
    }

    file { "${title}_keys":
      name => "/home/$title/.ssh/authorized_keys",
      owner => $title,
      group => $title,
      mode => 400,
      content => $sshkeys,
      ensure => 'present',
      require => File["${title}_sshdir"],
    }
  }
}
