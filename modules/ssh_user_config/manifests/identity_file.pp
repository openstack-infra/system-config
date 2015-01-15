define ssh_user_config::identity_file (
  $content = '',
  $user,
  $homedir,
) {
  $identity_file = $title ? {
    'id_rsa' => "${homedir}/.ssh/id_rsa",
    default  => "${homedir}/.ssh/${title}.id_rsa",
  }

  if $identity != '' {
    if (!defined($identity_file)) {
      file { $identity_file:
        owner   => $user,
        group   => $user,
        ensure  => present,
        content => $content,
        mode    => '0400',
        require => File["${homedir}/.ssh/config"],
      }
    }
  }
}
