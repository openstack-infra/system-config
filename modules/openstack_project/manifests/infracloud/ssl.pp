define openstack_project::infracloud::ssl(
  $key_content,
  $cert_content,
  $key_path = undef,
  $cert_path = undef,
) {
  if $key_path == undef {
    $_key_path  = "/etc/${name}/ssl/private/${::fqdn}.pem"
  } else {
    $_key_path = $key_path
  }
  if $cert_path == undef {
    $_cert_path = "/etc/${name}/ssl/certs/${::fqdn}.pem"
  } else {
    $_cert_path = $cert_path
  }

  # If the user isn't providing an unexpected path, create the directory
  # structure.
  if $key_path == undef and $cert_path == undef {
    file { "/etc/${name}/ssl":
      ensure => directory,
      owner  => $name,
      mode   => '0775',
    }
    file { "/etc/${name}/ssl/private":
      ensure  => directory,
      owner   => $name,
      mode    => '0755',
      require => File["/etc/${name}/ssl"],
      before  => File[$_key_path]
    }
    file { "/etc/${name}/ssl/certs":
      ensure  => directory,
      owner   => $name,
      mode    => '0750',
      require => File["/etc/${name}/ssl"],
      before  => File[$_cert_path],
    }
  }

  file { $_key_path:
    ensure  => present,
    content => $key_content,
    owner   => $name,
    mode    => '0600',
  }
  file { $_cert_path:
    ensure  => present,
    content => $cert_content,
    mode    => '0644',
  }
}
