# Class to configure ssl-cert-check on a node.
class opencontrail_project::ssl_cert_check {
  class { '::ssl_cert_check':
    domainlist_file => '/var/lib/certcheck/ssldomains',
    email           => 'root',
    days            => '30'
  }

  file { '/var/lib/certcheck/ssldomains':
      ensure  => present,
      owner   => 'certcheck',
      group   => 'certcheck',
      mode    => '0444',
      source  => 'puppet:///modules/opencontrail_project/ssl_cert_check/ssldomains'
  }
}
