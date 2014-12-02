# == Class: openstack_project::storyboard
#
class openstack_project::storyboard(
  $mysql_host = '',
  $mysql_password = '',
  $mysql_user = '',
  $rabbitmq_user = 'storyboard',
  $rabbitmq_password,
  $sysadmins = [],
  $ssl_cert_file_contents = undef,
  $ssl_key_file_contents = undef,
  $ssl_chain_file_contents = undef,
  $openid_url = 'https://login.launchpad.net/+openid',
  $project_config_repo = '',
) {

  class { 'project_config':
    url  => $project_config_repo,
  }

  class { 'openstack_project::server':
    sysadmins                 => $sysadmins,
    iptables_public_tcp_ports => [80, 443],
  }

  mysql_backup::backup_remote { 'storyboard':
    database_host     => $mysql_host,
    database_user     => $mysql_user,
    database_password => $mysql_password,
    require           => Class['::storyboard::application'],
  }

  class { '::storyboard::cert':
    ssl_cert_content => $ssl_cert_file_contents,
    ssl_cert         => '/etc/ssl/certs/storyboard.openstack.org.pem',
    ssl_key_content  => $ssl_key_file_contents,
    ssl_key          => '/etc/ssl/private/storyboard.openstack.org.key',
    ssl_ca_content   => $ssl_chain_file_contents,
  }

  class { '::storyboard::application':
    hostname               => $::fqdn,
    cors_allowed_origins   => [
      'https://storyboard.openstack.org',
      'http://docs-draft.openstack.org',
    ],
    cors_max_age           => 3600,
    openid_url             => $openid_url,
    mysql_host             => $mysql_host,
    mysql_database         => 'storyboard',
    mysql_user             => $mysql_user,
    mysql_user_password    => $mysql_password,
    rabbitmq_host          => 'localhost',
    rabbitmq_port          => 5672,
    rabbitmq_vhost         => '/',
    rabbitmq_user          => $rabbitmq_user,
    rabbitmq_user_password => $rabbitmq_password,
  }

  class { '::storyboard::rabbit':
    rabbitmq_user          => $rabbitmq_user,
    rabbitmq_user_password => $rabbitmq_password,
  }

  class { '::storyboard::workers':
    worker_count => 5,
  }

  # Load the projects into the database.
  class { '::storyboard::load_projects':
    source  => $::project_config::jeepyb_project_file,
    require => $::project_config::config_dir,
  }

  # Load the superusers into the database
  class { '::storyboard::load_superusers':
    source => 'puppet:///modules/openstack_project/storyboard/superusers.yaml',
  }

  include bup
  bup::site { 'rs-ord':
    backup_user   => 'bup-storyboard',
    backup_server => 'ci-backup-rs-ord.openstack.org',
  }
}
