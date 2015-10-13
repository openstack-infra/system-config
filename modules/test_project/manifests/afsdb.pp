# AFS DB Server
class test_project::afsdb (
) {

  class { '::test_project::afsfs': }

  class { '::openafs::dbserver':
    require => Class['Openstack_project::Afsfs'],
  }

}
