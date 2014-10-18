class openafs::dbserver {

  $packages = [
    "openafs-dbserver",
  ]
  package { $packages:
    ensure  => present,
    require => Class['openafs::fileserver'],
  }
}
