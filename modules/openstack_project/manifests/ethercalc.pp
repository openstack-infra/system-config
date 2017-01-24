class openstack_project::ethercalc (
  $ssl_cert_file = '/etc/ssl/certs/ethercalc.openstack.org.pem',
  $ssl_key_file = '/etc/ssl/private/ethercalc.openstack.org.key',
  $ssl_chain_file = '/etc/ssl/certs/intermediate.pem',
  $ssl_cert_file_contents = '',
  $ssl_key_file_contents = '',
  $ssl_chain_file_contents = '',
) {
  include ethercalc

  class { 'ethercalc::apache':
    ssl_cert_file           => $ssl_cert_file,
    ssl_key_file            => $ssl_key_file,
    ssl_chain_file          => $ssl_chain_file,
    ssl_cert_file_contents  => $ssl_cert_file_contents,
    ssl_key_file_contents   => $ssl_key_file_contents,
    ssl_chain_file_contents => $ssl_chain_file_contents,
  }

  # TODO(clarkb) Redis backups
  include ethercalc::redis
}
