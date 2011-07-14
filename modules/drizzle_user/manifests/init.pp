define drizzle_user ( $username, $fullname ) {

  group { $username:
    ensure => 'present'
  }

  user { $username:
    ensure => 'present',
    comment => $fullname,
    home => $operatingsystem ? {
      Darwin => '/Users/$username',
      solaris => '/export/home/$username',
      default => '/home/$username',
    },
    managehome => true,
  }

  
  file { 'sshdir':
    name => $operatingsystem ? {
      Darwin => '/Users/$username/.ssh',
      solaris => '/export/home/$username/.ssh',
      default => '/home/$username/.ssh',
    },
    owner => $username,
    group => $username,
    mode => 600,
    ensure => 'directory',
    require => User[$username],
  }

}
