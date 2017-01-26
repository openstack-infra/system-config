class openstack_project::ethercalc (
  $vhost_name = $::fqdn,
  $ssl_cert_file = '/etc/ssl/certs/ethercalc.openstack.org.pem',
  $ssl_key_file = '/etc/ssl/private/ethercalc.openstack.org.key',
  $ssl_chain_file = '/etc/ssl/certs/intermediate.pem',
  $ssl_cert_file_contents = '',
  $ssl_key_file_contents = '',
  $ssl_chain_file_contents = '',
) {
  class { '::ethercalc': }

  class { 'ethercalc::apache':
    vhost_name              => $vhost_name,
    ssl_cert_file           => $ssl_cert_file,
    ssl_key_file            => $ssl_key_file,
    ssl_chain_file          => $ssl_chain_file,
    ssl_cert_file_contents  => $ssl_cert_file_contents,
    ssl_key_file_contents   => $ssl_key_file_contents,
    ssl_chain_file_contents => $ssl_chain_file_contents,
  }

  include ethercalc::redis

  # Redis creates a snapshot at /var/lib/redis/dump.rdb periodically
  # (at worst every 15 minutes if at least one change is made to redis)
  # which can be used to recover the Redis DB. Bup will automagically
  # pick this file up during its normal operation so no other DB dumping
  # is required like with mysql.
  include bup
  bup::site { 'rs-ord':
    backup_user   => 'bup-etherpad',
    backup_server => 'ci-backup-rs-ord.openstack.org',
  }
}
