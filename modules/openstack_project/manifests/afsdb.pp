# AFS DB Server
class openstack_project::afsdb (
) {

  class { '::openstack_project::afsfs': }

  class { '::openafs::dbserver':
    require => Class['Openstack_project::Afsfs'],
  }

}
