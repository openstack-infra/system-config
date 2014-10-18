# AFS Fileserver/BOS
class openstack_project::afsfs (
  $cell = 'openstack.org',
  $sysadmins = [],
) {

  class { 'openstack_project::afs':
    sysadmins                 => $sysadmins
  }

  class { 'afs::fileserver':
    cell         => $cell
    dbservers    => [
      {
        name     => 'afsdb01.openstack.org',
        ip       => '104.130.136.20',
      },
      {
        name     => 'afsdb02.openstack.org',
        ip       => '23.253.200.228',
      },
    ],
    admins       => [
      'mordred',
      'corvus',
      'fungi',
      'clarkb',
      'slukjanov',
    ],
    require      => Class['Openstack_project::Afs'],
  }
}
