class afs::dbserver {

  $packages = [
    "openafs-dbserver",
  ]
  package { $packages:
    ensure  => present,
    require => Class['afs::fileserver'],
  }
}
