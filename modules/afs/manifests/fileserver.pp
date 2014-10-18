class afs::fileserver (
  $realm,
  $kdcs = [$::fqdn],
  $admin_server = [$::fdqn],
) {

  class { 'afs::client':
    realm          => $realm,
    kdcs           => $kdcs,
    admin_server   => $admin_server,
  }

  $packages = [
    'openafs-fileserver',
  ]
  package { $packages:
    ensure  => present,
    require => Class['afs::client'],
  }

}
