define openstack_project::infracloud::ssl(
  $key_content,
  $cert_content,
  $chain_content = undef,
) {
  $key_path  = "/etc/${name}/ssl/private/${::fqdn}.pem"
  $cert_path = "/etc/${name}/ssl/certs/${::fqdn}.pem"
  $chain_path = "/etc/${name}/ssl/certs/${::fqdn}_ca.pem"
  file { "/etc/${name}/ssl":
    ensure => directory,
    owner  => $name,
    mode   => '0775',
  }
  file { "/etc/${name}/ssl/private":
    ensure => directory,
    owner  => $name,
    mode   => '0755',
    require => File["/etc/${name}/ssl"],
  }
  file { "/etc/${name}/ssl/certs":
    ensure => directory,
    owner  => $name,
    mode   => '0750',
    require => File["/etc/${name}/ssl"],
  }
  file { $key_path:
    ensure  => present,
    content => $key_content,
    owner   => $name,
    mode    => '0600',
    require => File["/etc/${name}/ssl/private"],
  }
  file { $cert_path:
    ensure  => present,
    content => $cert_content,
    mode    => '0644',
    require => File["/etc/${name}/ssl/certs"],
  }
  if $chain_content != undef {
    file { $chain_path:
      ensure  => present,
      content => $chain_content,
      mode    => '0644',
      require => File["/etc/${name}/ssl/certs"],
    }
  }
}
