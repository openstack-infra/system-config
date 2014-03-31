# == Class: openstack_project::jenkins_dev
#
class openstack_project::jenkins_dev (
  $jenkins_ssh_private_key = '',
  $sysadmins = [],
  $mysql_root_password,
  $mysql_password,
  $nodepool_ssh_private_key = '',
  $jenkins_api_user ='',
  $jenkins_api_key ='',
  $jenkins_credentials_id ='',
  $hpcloud_username ='',
  $hpcloud_password ='',
  $hpcloud_project ='',
) {
  include openstack_project

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
    sysadmins                 => $sysadmins,
  }
  include bup
  bup::site { 'rs-ord':
    backup_user   => 'bup-jenkins-dev',
    backup_server => 'ci-backup-rs-ord.openstack.org',
  }
  class { '::jenkins::master':
    vhost_name              => 'jenkins-dev.openstack.org',
    serveradmin             => 'webmaster@openstack.org',
    logo                    => 'openstack.png',
    ssl_cert_file           => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
    ssl_key_file            => '/etc/ssl/private/ssl-cert-snakeoil.key',
    ssl_chain_file          => '',
    jenkins_ssh_private_key => $jenkins_ssh_private_key,
    jenkins_ssh_public_key  => $openstack_project::jenkins_dev_ssh_key,
  }

  file { '/etc/default/jenkins':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/openstack_project/jenkins/jenkins.default',
  }

  class { '::nodepool':
    mysql_password           => 'mysql_password',
    mysql_root_password      => 'mysql_root_password',
    nodepool_ssh_private_key => 'nodepool_ssh_private_key',
    nodepool_template        => 'nodepool-dev.yaml.erb',
    sysadmins                => 'sysadmins',
    jenkins_api_user         => 'jenkins_api_user',
    jenkins_api_key          => 'jenkins_api_key',
    jenkins_credentials_id   => 'jenkins_credentials_id',
    hpcloud_username         => 'hpcloud_username',
    hpcloud_password         => 'hpcloud_password',
    hpcloud_project          => 'hpcloud_project',
  }

}
