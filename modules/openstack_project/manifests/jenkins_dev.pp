# == Class: openstack_project::jenkins_dev
#
class openstack_project::jenkins_dev (
  $project_config_repo = '',
  $jenkins_ssh_private_key = '',
  $mysql_root_password,
  $mysql_password,
  $nodepool_ssh_private_key = '',
  $jenkins_api_user ='',
  $jenkins_api_key ='',
  $jenkins_credentials_id ='',
  $hpcloud_username ='',
  $hpcloud_password ='',
  $hpcloud_project ='',
  $nodepool_template ='nodepool-dev.yaml.erb',
  $jenkins_dev_ssh_key,
) {

  realize (
    User::Virtual::Localuser['zaro'],
  )

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
    jenkins_ssh_public_key  => $jenkins_dev_ssh_key,
  }

  jenkins::plugin { 'build-timeout':
    version => '1.14',
  }
  jenkins::plugin { 'copyartifact':
    version => '1.22',
  }
  jenkins::plugin { 'dashboard-view':
    version => '2.3',
  }
  jenkins::plugin { 'gearman-plugin':
    version => '0.1.3',
  }
  jenkins::plugin { 'git':
    version => '1.1.23',
  }
  jenkins::plugin { 'greenballs':
    version => '1.12',
  }
  jenkins::plugin { 'extended-read-permission':
    version => '1.0',
  }
  jenkins::plugin { 'zmq-event-publisher':
    version => '0.0.3',
  }
#  TODO(jeblair): release
#  jenkins::plugin { 'scp':
#    version => '1.9',
#  }
  jenkins::plugin { 'jobConfigHistory':
    version => '1.13',
  }
  jenkins::plugin { 'monitoring':
    version => '1.40.0',
  }
  jenkins::plugin { 'nodelabelparameter':
    version => '1.2.1',
  }
  jenkins::plugin { 'notification':
    version => '1.4',
  }
  jenkins::plugin { 'openid':
    version => '1.5',
  }
  jenkins::plugin { 'postbuildscript':
    version => '0.16',
  }
  jenkins::plugin { 'publish-over-ftp':
    version => '1.7',
  }
  jenkins::plugin { 'simple-theme-plugin':
    version => '0.2',
  }
  jenkins::plugin { 'timestamper':
    version => '1.3.1',
  }
  jenkins::plugin { 'token-macro':
    version => '1.5.1',
  }

  class { '::nodepool':
    mysql_root_password      => $mysql_root_password,
    mysql_password           => $mysql_password,
    nodepool_ssh_private_key => $nodepool_ssh_private_key,
    environment              => {
      'NODEPOOL_SSH_KEY'     => $jenkins_dev_ssh_key,
    }
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
    purge   => true,
    force   => true,
    require => [
      File['/etc/nodepool'],
      Class['project_config'],
    ],
    source  => $::project_config::nodepool_scripts_dir,
  }

  if ! defined(Class['project_config']) {
    class { 'project_config':
      url  => $project_config_repo,
    }
  }

}
