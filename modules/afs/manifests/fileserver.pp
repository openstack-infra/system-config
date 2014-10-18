class afs::fileserver (
  $cell,
  $dbservers,
  $admins = [],
) {

  file { '/etc/openafs/server':
    ensure  => directory,
    require => Class['Afs::Client'],
  }

  file { '/etc/openafs/server/CellServDB':
    ensure  => present,
    replace => true,
    content => template('afs/server.CellServDB.erb'),
    require => File['/etc/openafs/server'],
  }

  file { '/etc/openafs/server/ThisCell':
    ensure  => present,
    replace => true,
    content => template('afs/ThisCell.erb'),
    require => File['/etc/openafs/server'],
  }

  file { '/etc/openafs/server/UserList':
    ensure  => present,
    replace => true,
    content => template('afs/UserList.erb'),
    require => File['/etc/openafs/server'],
  }

  package { 'openafs-fileserver':
    ensure  => present,
    require => [
      File['/etc/openafs/server/UserList'],
      File['/etc/openafs/server/CellServDB'],
    ],
  }

  # yes, this belongs here. the fileserver service runs bosserver
  service { 'openafs-fileserver':
    ensure    => running,
    subscribe => [
      File['/etc/openafs/server/UserList'],
      File['/etc/openafs/server/CellServDB'],
    ],
    require   => [
      File['/etc/openafs/server/UserList'],
      File['/etc/openafs/server/CellServDB'],
      Package['openafs-fileserver'],
    ],
  }
}
