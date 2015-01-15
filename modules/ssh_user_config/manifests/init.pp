define ssh_user_config (
  $user           = $title,
  $config_options = {},
) {
  $homedir = $user ? {
    root    => '/root',
    default => "/home/${user}",
  }

  $default_options = {
    'user'    => $user,
    'homedir' => $homedir,
  }

  if !defined(File["${homedir}/.ssh"]) {
    file{ "${homedir}/.ssh":
      ensure => directory,
      owner  => $user,
      group  => $user,
    }
  }

  if has_key($config_options, 'hosts') {
    file { "${homedir}/.ssh/config":
      ensure  => present,
      owner   => $user,
      group   => $user,
      mode    => '0600',
      content => template('ssh_user_config/config.erb'),
    }
  } else {
    file { "${homedir}/.ssh/config":
      ensure  => present,
      owner   => $user,
      group   => $user,
      mode    => '0600',
    }
  }

  if has_key($config_options, 'identities') {
    create_resources('ssh_user_config::identity_file', $config_options['identities'], $default_options)
  }
}

# config_options example
#config_options = {
#  'hosts' => {
#    'review.fuel-infra.org' => {
#      'IdentityFile' => 'id_rsa'
#    },
#  },
#  'identities' => {
#    'id_rsa' => {
#      'content' => $identity,
#    },
#  },
#}
