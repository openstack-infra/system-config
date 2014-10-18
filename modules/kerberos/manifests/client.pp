class kerberos::client (
  $kdcs,
  $admin_server,
  $realm = upcase($domain),
  $default_domain = $domain,
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
