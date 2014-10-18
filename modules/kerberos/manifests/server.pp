class kerberos::server (
  $realm = upcase($::domain),
  $kdcs = [$::fqdn],
  $admin_server = [$::fdqn],
  $slave = false,
) {

  include ntp
  class { 'kerberos::client':
    realm          => $realm,
    kdcs           => $kdcs,
    admin_server   => $admin_server,
    default_domain => $::domain,
  }

  $packages = [
    'haveged',
    'krb5-admin-server',
    'krb5-kdc',
  ]
  package { $packages:
    ensure  => present,
    require => Class['krb'],
  }

  file { '/etc/krb5kdc/kdc.conf':
    ensure  => present,
    replace => true,
    content => template('kerberos/kdc.conf.erb'),
    require   => Package['krb5-kdc'],
  }

  file { '/etc/krb5kdc/kadm5.acl':
    ensure  => present,
    replace => true,
    source  => 'puppet:///modules/kerberos/kadm5.acl',
    require   => Package['krb5-admin-server'],
  }

  if ($slave) {
    $run_admin_server = running
  } else {
    $run_admin_server = stopped
  }
  service { 'krb5-admin-server':
    ensure => $run_admin_server,
    subscribe => File['/etc/krb5kdc/kadm5.acl'],
    require   => [
      File['/etc/krb5kdc/kadm5.acl'],
      Package['krb5-admin-server'],
    ],
  }
}
