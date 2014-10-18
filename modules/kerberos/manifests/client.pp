class kerberos::client (
  $realm,
  $kdcs,
  $admin_server,
  $this_is_kdc = false,
) {

  package { 'krb5-user':
    ensure  => present,
    require => File['/etc/krb5.conf'],
  }

  file { '/etc/krb5.conf':
    ensure  => present,
    replace => true,
    content => template('kerberos/krb5.conf.erb'),
  }
}
