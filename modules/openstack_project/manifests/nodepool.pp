# == Class: openstack_project::nodepool
#
class openstack_project::nodepool(
  $mysql_root_password,
  $mysql_password,
  $nodepool_ssh_private_key = '',
  $nodepool_template = 'nodepool.yaml.erb',
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

  file { '/etc/nodepool/nodepool.yaml':
    ensure  => present,
    owner   => 'nodepool',
    group   => 'root',
    mode    => '0400',
    content => template("openstack_project/nodepool/${nodepool_template}"),
    require => [
      File['/etc/nodepool'],
      User['nodepool'],
    ],
  }

  file { '/etc/nodepool/scripts':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    recurse => true,
    require => File['/etc/nodepool'],
    source  => 'puppet:///modules/openstack_project/nodepool/scripts',
  }

}
