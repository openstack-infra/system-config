# == Class: opencontrail_project::jenkins_dev
#
class opencontrail_project::jenkins_dev (
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
  include opencontrail_project

  class { 'opencontrail_project::server':
    iptables_public_tcp_ports => [80, 443],
    sysadmins                 => $sysadmins,
  }
  include bup
  bup::site { 'rs-ord':
    backup_user   => 'bup-jenkins-dev',
    backup_server => 'ci-backup-rs-ord.opencontrail.org',
  }
  class { '::jenkins::master':
    vhost_name              => 'jenkins-dev.opencontrail.org',
    serveradmin             => 'webmaster@opencontrail.org',
    logo                    => 'opencontrail.png',
    ssl_cert_file           => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
    ssl_key_file            => '/etc/ssl/private/ssl-cert-snakeoil.key',
    ssl_chain_file          => '',
    jenkins_ssh_private_key => $jenkins_ssh_private_key,
    jenkins_ssh_public_key  => $opencontrail_project::jenkins_dev_ssh_key,
  }

  file { '/etc/default/jenkins':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/opencontrail_project/jenkins/jenkins.default',
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
