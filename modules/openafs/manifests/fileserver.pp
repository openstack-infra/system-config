class openafs::fileserver (
  $cell,
  $dbservers,
) {

  file { '/etc/openafs/server':
    ensure  => directory,
    require => Class['Afs::Client'],
  }

  file { '/etc/openafs/server/CellServDB':
    ensure  => present,
    replace => true,
    content => template('openafs/server.CellServDB.erb'),
    require => File['/etc/openafs/server'],
  }

  file { '/etc/openafs/server/ThisCell':
    ensure  => present,
    replace => true,
    content => template('openafs/ThisCell.erb'),
    require => File['/etc/openafs/server'],
  }

  package { 'openafs-fileserver':
    ensure  => present,
    require => [
      File['/etc/openafs/server/CellServDB'],
    ],
  }

  # yes, this belongs here. the fileserver service runs bosserver
  service { 'openafs-fileserver':
    ensure    => running,
    require   => [
      File['/etc/openafs/server/CellServDB'],
      Package['openafs-fileserver'],
    ],
  }
}
