# == Class: openstack_project::storyboard::dev
#
class openstack_project::storyboard::dev(
  $mysql_host = '',
  $mysql_password = '',
  $mysql_user = '',
  $rabbitmq_user = 'storyboard',
  $rabbitmq_password,
  $sysadmins = [],
  $ssl_cert_file_contents = undef,
  $ssl_key_file_contents = undef,
  $ssl_chain_file_contents = undef,
  $openid_url = 'https://login.ubuntu.com/+openid',
  $project_config_repo = '',
  $hostname = $::fqdn,
  $valid_oauth_clients = [$::fqdn],
  $cors_allowed_origins = ["https://${::fqdn}"],
  $sender_email_address = undef,
) {

  class { 'openstack_project::storyboard':
    project_config_repo     => $project_config_repo,
    sysadmins               => $sysadmins,
    superusers              =>
      'puppet:///modules/openstack_project/storyboard/dev_superusers.yaml',
    mysql_host              => $mysql_host,
    mysql_user              => $mysql_user,
    mysql_password          => $mysql_password,
    rabbitmq_user           => $rabbitmq_user,
    rabbitmq_password       => $rabbitmq_password,
    ssl_cert_file_contents  => $ssl_cert_file_contents,
    ssl_key_file_contents   => $ssl_key_file_contents,
    ssl_chain_file_contents => $ssl_chain_file_contents,
    hostname                => $hostname,
    valid_oauth_clients     => $valid_oauth_clients,
    cors_allowed_origins    => $cors_allowed_origins,
    sender_email_address    => $sender_email_address,
  }

  realize (
    User::Virtual::Localuser['SotK'],
    User::Virtual::Localuser['Zara'],
  )


}
