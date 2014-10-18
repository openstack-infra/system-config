class afs::client (
  $realm,
  $kdcs = [$::fqdn],
  $admin_server = [$::fdqn],
) {

  include ntp
  class { 'kerberos::client':
    realm          => $realm,
    kdcs           => $kdcs,
    admin_server   => $admin_server,
  }

  $packages = [
    'openafs-client',
    'openafs-krb5',
  ]
  package { $packages:
    ensure  => present,
  }

  file { '/etc/openafs/CellServDB':
    ensure  => present,
    replace => true,
    source  => 'puppet:///modules/afs/CellServDB',
    require => Package['openafs-client'],
  }

  file { '/etc/openafs/ThisCell':
    ensure  => present,
    replace => true,
    source  => 'puppet:///modules/afs/ThisCell',
    require => Package['openafs-client'],
  }

}
