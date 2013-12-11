# == Class: openstack_project::nodepool_host
#
class openstack_project::nodepool_host(
  $mysql_root_password,
  $mysql_password,
  $nodepool_ssh_private_key = '',
  $sysadmins = [],
  $statsd_host = '',
  $jenkins_api_user ='',
  $jenkins_api_key ='',
  $jenkins_credentials_id ='',
  $rackspace_username ='',
  $rackspace_password ='',
  $rackspace_project ='',
  $hpcloud_username ='',
  $hpcloud_password ='',
  $hpcloud_project ='',
  $tripleo_username ='',
  $tripleo_password ='',
  $tripleo_project ='',
) {
  class { 'openstack_project::server':
    sysadmins                 => $sysadmins,
  }

  class { '::nodepool':
    mysql_root_password      => $mysql_root_password,
    mysql_password           => $mysql_password,
    nodepool_ssh_private_key => $nodepool_ssh_private_key,
    statsd_host              => $statsd_host,
  }

  class { '::nodepool_service':
    mysql_root_password      => $mysql_root_password,
    mysql_password           => $mysql_password,
    nodepool_template        => 'nodepool.yaml.erb',
    jenkins_api_user         => $jenkins_api_user,
    jenkins_api_key          => $jenkins_api_key,
    jenkins_credentials_id   => $jenkins_credentials_id,
    rackspace_username       => $rackspace_username,
    rackspace_password       => $rackspace_password,
    rackspace_project        => $rackspace_project,
    hpcloud_username         => $hpcloud_username,
    hpcloud_password         => $hpcloud_password,
    hpcloud_project          => $hpcloud_project,
    tripleo_username         => $tripleo_username,
    tripleo_password         => $tripleo_password,
    tripleo_project          => $tripleo_project,
  }

}
