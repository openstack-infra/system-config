# AFS Fileserver/BOS
class openstack_project::afsfs (
  $cell = 'openstack.org',
) {

  class { '::openafs::fileserver':
    cell         => $cell,
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
  }
}
