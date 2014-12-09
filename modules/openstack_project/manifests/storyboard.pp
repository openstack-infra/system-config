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

  # Set all the configuration parameters for storyboard.
  class { '::storyboard::params':
    hostname               => $::fqdn,
    openid_url             => $openid_url,
    valid_oauth_clients    => [$hostname, 'docs-draft.openstack.org'],
    enable_cron            => false,
    cors_allowed_origins   => [
      'https://storyboard.openstack.org',
      'http://docs-draft.openstack.org',
    ],
    mysql_host             => $mysql_host,
    mysql_user             => $mysql_user,
    mysql_user_password    => $mysql_password,
    rabbitmq_user          => $rabbitmq_user,
    rabbitmq_user_password => $rabbitmq_password,
    enable_token_cleanup   => true,
    worker_count           => 5,
    ssl_cert_content       => $ssl_cert_file_contents,
    ssl_cert               => '/etc/ssl/certs/storyboard.openstack.org.pem',
    ssl_key_content        => $ssl_key_file_contents,
    ssl_key                => '/etc/ssl/private/storyboard.openstack.org.key',
    ssl_ca_content         => $ssl_chain_file_contents,
  }

  # Install all the things.
  if $::storyboard::params::ssl_cert_content == undef {
    include ::storyboard::apache::http
  } else {
    include ::storyboard::apache::https
  }
  include ::storyboard::rabbit
  include ::storyboard::mysql
  include ::storyboard::application
  include ::storyboard::workers

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
