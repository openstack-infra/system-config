# == Class: openstack_project::pholio
#

class openstack_project::pholio (
  $mysql_root_password,
  $mysql_user_password,
  $ssl_cert_file = undef,
  $ssl_key_file = undef,
  $ssl_chain_file = undef,
  $ssl_cert_file_contents = undef,
  $ssl_key_file_contents = undef,
  $ssl_chain_file_contents = undef,
) {

  class { '::phabricator':
    mysql_root_password     => $mysql_root_password,
    mysql_user_password     => $mysql_user_password,
    ssl_cert_file           => $ssl_cert_file,
    ssl_key_file            => $ssl_key_file,
    ssl_chain_file          => $ssl_chain_file,
    ssl_cert_file_contents  => $ssl_cert_file_contents,
    ssl_key_file_contents   => $ssl_key_file_contents,
    ssl_chain_file_contents => $ssl_chain_file_contents,
  }

}
