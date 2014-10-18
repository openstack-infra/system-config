class kerberos::server (
  $realm = upcase($::domain),
  $kdcs = [$::fqdn],
  $admin_server = [$::fdqn],
  $slaves = [],
  $slave = false,
) {

  include ntp
  class { 'kerberos::client':
    realm          => $realm,
    kdcs           => $kdcs,
    admin_server   => $admin_server,
    default_domain => $::domain,
    this_is_kdc    => true,
  }

  $packages = [
    'haveged',
    'krb5-admin-server',
    'krb5-kdc',
  ]
  package { $packages:
    ensure  => present,
  }

  file { '/etc/krb5kdc/kdc.conf':
    ensure  => present,
    replace => true,
    content => template('kerberos/kdc.conf.erb'),
    require   => Package['krb5-kdc'],
  }

  file { '/etc/krb5kdc/kpropd.acl':
    ensure  => present,
    replace => true,
    content => template('kerberos/kpropd.acl.erb'),
    require   => Package['krb5-kdc'],
  }

  file { '/etc/krb5kdc/kadm5.acl':
    ensure  => present,
    replace => true,
    source  => 'puppet:///modules/kerberos/kadm5.acl.erb',
    require => Package['krb5-admin-server'],
  }

  file { '/var/krb5kdc':
    ensure => directory,
  }

  file { '/etc/init.d/krb5-kpropd':
    ensure  => present,
    replace => true,
    source  => 'puppet:///modules/kerberos/krb5-kpropd',
    require => Package['krb5-admin-server'],
  }

  file { '/usr/local/bin/kprop-openstack.sh':
    ensure  => present,
    replace => true,
    mode    => 0755,
    source  => 'puppet:///modules/kerberos/kprop-openstack.sh.erb',
    require => Package['krb5-admin-server'],
  }

  if ($slave) {
    $run_admin_server = running
    $run_kpropd = stopped
    $kprop_cron = absent
  } else {
    $run_admin_server = stopped
    $run_kpropd = running
    $kprop_cron = present
  }

  cron { 'kprop':
    ensure      => $kprop_cron,
    user        => 'root',
    minute      => '*/15',
    command     => '/usr/local/bin/kprop-openstack.sh >/dev/null 2>&1',
    environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
  }

  service { 'krb5-kpropd':
    ensure => $run_kpropd,
    require   => [
      File['/etc/init.d/krb5-kpropd'],
      Package['krb5-admin-server'],
    ],
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
