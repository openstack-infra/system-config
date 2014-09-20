# == Class: openstack_project::nodepool_prod
#
class openstack_project::nodepool_prod(
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
  $image_log_document_root = '/var/log/nodepool/image',
  $enable_image_log_via_http = true,
  $project_config_repo = '',
) {
  class { 'openstack_project::server':
    sysadmins                 => $sysadmins,
    iptables_public_tcp_ports => [80],
  }

  class { 'project_config':
    url  => $project_config_repo,
  }

  class { '::nodepool':
    mysql_root_password       => $mysql_root_password,
    mysql_password            => $mysql_password,
    nodepool_ssh_private_key  => $nodepool_ssh_private_key,
    statsd_host               => $statsd_host,
    image_log_document_root   => $image_log_document_root,
    enable_image_log_via_http => $enable_image_log_via_http,
    scripts_dir               => $::project_config::nodepool_scripts_dir,
    elements_dir              => $::project_config::nodepool_elements_dir,
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
}
