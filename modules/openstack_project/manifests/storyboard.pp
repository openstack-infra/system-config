# == Class: openstack_project::storyboard
#
class openstack_project::storyboard(
  $mysql_host = '',
  $mysql_password = '',
  $mysql_user = '',
  $rabbitmq_user = 'storyboard',
  $rabbitmq_password,
  $sysadmins = [],
  $ssl_cert = undef,
  $ssl_cert_file_contents = undef,
  $ssl_key = undef,
  $ssl_key_file_contents = undef,
  $ssl_chain_file_contents = undef,
  $openid_url = 'https://login.launchpad.net/+openid',
  $project_config_repo = '',
  $hostname = $::fqdn,
  $valid_oauth_clients = [$::fqdn],
  $cors_allowed_origins = ["https://${::fqdn}"],
  $sender_email_address = undef,
) {

  class { 'project_config':
    url  => $project_config_repo,
  }

  class { 'openstack_project::server':
    sysadmins                 => $sysadmins,
    iptables_public_tcp_ports => [80, 443],
    manage_exim               => false,
  }

  class { '::exim':
    sysadmins => $sysadmins,
    routers => [
      {'storyboard_verp_router' => {
        'driver'              => 'dnslookup',
        # we only consider messages sent in through loopback
        'condition' => '${if or{{eq{$sender_host_address}{127.0.0.1}}\
                         {eq{$sender_host_address}{::1}}}{yes}{no}}',
        # we do not do this for traffic going to the local machine
        'domains'             => '!+local_domains',
        'ignore_target_hosts' => '<; 0.0.0.0; 64.94.110.11; 127.0.0.0/8; \
                                  ::1/128;fe80::/10;fec0::/10;ff00::/8',
        # only the un-VERPed bounce addresses are handled
        'senders'             => '"*-bounces@*"',
        'transport'           => 'storyboard_verp_smtp',
      }},
      # Send bounces to /dev/null until storyboard supports them.
      {'storyboard' => {
        'driver'                     => 'redirect',
        'local_parts'                => 'storyboard',
        'local_part_suffix_optional' => true,
        'local_part_suffix'          => '-bounces : -bounces+*',
        'data'                       => ':blackhole:',
      }}
      ],
    transports => [
      {'storyboard_verp_smtp' => {
        'driver'         => 'smtp',
        'return_path'    => '${local_part:$return_path}+$local_part\
                             =$domain@${domain:$return_path}',
        'max_rcpt'       => '1',
        'headers_remove' => 'Errors-To',
        'headers_add'    => 'Errors-To: ${return_path}',
      }}
      ],
  }

  mysql_backup::backup_remote { 'storyboard':
    database_host     => $mysql_host,
    database_user     => $mysql_user,
    database_password => $mysql_password,
    require           => Class['::storyboard::application'],
  }

  class { '::storyboard::cert':
    ssl_cert_content => $ssl_cert_file_contents,
    ssl_cert         => $ssl_cert,
    ssl_key_content  => $ssl_key_file_contents,
    ssl_key          => $ssl_key,
    ssl_ca_content   => $ssl_chain_file_contents,
  }

  class { '::storyboard::application':
    hostname               => $hostname,
    cors_allowed_origins   => $cors_allowed_origins,
    valid_oauth_clients    => $valid_oauth_clients,
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
    sender_email_address   => $sender_email_address,
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
