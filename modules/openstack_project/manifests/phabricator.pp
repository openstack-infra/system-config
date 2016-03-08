# == Class: openstack_project::phabricator
#
class openstack_project::phabricator(
  $vhost_name               = $::fqdn,
  $phab_dir                 = '/phabricator',
  $instance                 = 'dev',
  $mysql_host               = 'localhost',
  $mysql_port               = 3306,
  $mysql_database           = 'phabricator',
  $mysql_user               = 'phabricator',
  $mysql_user_password      = '',
  $sysadmins                = [],
  $ssl_cert_file_contents   = undef,
  $ssl_key_file_contents    = undef,
  $ssl_chain_file_contents  = undef,
  $openid_url               = 'https://login.launchpad.net/+openid',
  $project_config_repo      = '',
  $hostname                 = $::fqdn,
  $valid_oauth_clients      = [$::fqdn],
  $cors_allowed_origins     = ["https://${::fqdn}"],
) {

  mysql_backup::backup_remote { 'phabricator':
    database_host     => $mysql_host,
    database_user     => $mysql_user,
    database_password => $mysql_password,
    require           => Class['::phabricator::application'],
  }

  class { '::phabricator':
    vhost_name                  => $vhost_name,
    phab_dir                    => $phab_dir,
    instance                    => $instance,
    mysql_host                  => $mysql_host,
    mysql_port                  => $mysql_port,
    mysql_database              => $mysql_database,
    mysql_user                  => $mysql_user,
    mysql_user_password         => $mysql_user_password,
    ssl_cert_file_contents      => $ssl_cert_file_contents,
    ssl_cert_file               => '/etc/ssl/certs/${::fqdn}.pem',
    ssl_key_file_contents       => $ssl_key_file_contents,
    ssl_key_file                => '/etc/ssl/private/${::fqdn}.key',
    ssl_chain_file_contents     => $ssl_chain_file_contents,
  }

  include ::bup
  bup::site { 'rs-ord':
    backup_user   => 'bup-phabricator',
    backup_server => 'ci-backup-rs-ord.openstack.org',
  }
}
