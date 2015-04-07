# AFS DB Server
class openstack_project::afsdb (
) {

  class { '::openstack_project::afsfs':
    sysadmins => $sysadmins,
  }

  class { '::openafs::dbserver':
    require => Class['Openstack_project::Afsfs'],
  }

}
