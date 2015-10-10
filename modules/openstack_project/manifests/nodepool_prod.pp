# == Class: openstack_project::nodepool_prod
#
class openstack_project::nodepool_prod(
  $nodepool_template = 'openstack_project/nodepool/nodepool.yaml.erb',
  $nodepool_logging_template = 'openstack_project/nodepool/nodepool.logging.conf.erb',
  $rackspace_username ='',
  $rackspace_password ='',
  $rackspace_project ='',
  $hpcloud_username ='',
  $hpcloud_password ='',
  $hpcloud_project ='',
  $ovh_username ='',
  $ovh_password ='',
  $ovh_project ='',
  $tripleo_username ='',
  $tripleo_password ='',
  $tripleo_project ='',
  $clouds_yaml_template = 'openstack_project/nodepool/clouds.yaml.erb',
) {

  file { '/etc/nodepool/nodepool.yaml':
    ensure  => present,
    owner   => 'nodepool',
    group   => 'root',
    mode    => '0400',
    content => template($nodepool_template),
    require => [
      File['/etc/nodepool'],
      User['nodepool'],
    ],
  }

  file { '/home/nodepool/.config':
    ensure => directory,
    owner   => 'nodepool',
    group   => 'nodepool',
    require => [
      User['nodepool'],
    ],
  }

  file { '/home/nodepool/.config/openstack':
    ensure => directory,
    owner   => 'nodepool',
    group   => 'nodepool',
    require => [
      File['/home/nodepool/.config'],
    ],
  }

  file { '/home/nodepool/.config/openstack/clouds.yaml':
    ensure  => present,
    owner   => 'nodepool',
    group   => 'nodepool',
    mode    => '0400',
    content => template($clouds_yaml_template),
    require => [
      File['/home/nodepool/.config/openstack'],
      User['nodepool'],
    ],
  }
}
