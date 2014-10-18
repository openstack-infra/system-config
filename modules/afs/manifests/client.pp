class afs::client (
  $realm,
  $cell,
  $kdcs = [$::fqdn],
  $admin_server = [$::fdqn],
  $cache_size = 500000,
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

  file { '/etc/openafs/afs.conf.client':
    ensure  => present,
    replace => true,
    source  => 'puppet:///modules/afs/afs.conf.client',
    require => Package['openafs-client'],
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
    content => template('afs/ThisCell.erb'),
    require => Package['openafs-client'],
  }

  file { '/etc/openafs/cacheinfo':
    ensure  => present,
    replace => true,
    content => template('afs/cacheinfo.erb'),
    require   => Package['openafs-client'],
  }

}
