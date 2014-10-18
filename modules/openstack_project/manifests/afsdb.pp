# AFS DD Server
class openstack_project::afsdb (
  $sysadmins = [],
) {
  class { 'openstack_project::afsfs':
    sysadmins => $sysadmins,
  }
  class { 'afs::dbserver':
    require => Class['Openstack_project::Afsfs'],
  }
}
