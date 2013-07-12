# == Class: openstack_project::review_dev
#
class openstack_project::review_dev (
  $github_oauth_token = '',
  $github_project_username = '',
  $github_project_password = '',
  $mysql_password = '',
  $mysql_root_password = '',
  $email_private_key = '',
  $contactstore_appsec = '',
  $contactstore_pubkey = '',
  $ssh_dsa_key_contents = '',
  $ssh_dsa_pubkey_contents = '',
  $ssh_rsa_key_contents = '',
  $ssh_rsa_pubkey_contents = '',
  $ssh_project_rsa_key_contents = '',
  $ssh_project_rsa_pubkey_contents = '',
  $lp_sync_key = '', # If left empty puppet will not create file.
  $lp_sync_pubkey = '', # If left empty puppet will not create file.
  $lp_sync_consumer_key = '',
  $lp_sync_token = '',
  $lp_sync_secret = '',
  $replicate_github = true,
  $sysadmins = [],
  $swift_username = '',
  $swift_password = ''
) {
  class { 'openstack_project::gerrit':
    vhost_name                      => 'review-dev.openstack.org',
    canonicalweburl                 => 'https://review-dev.openstack.org/',
    ssl_cert_file                   => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
    ssl_key_file                    => '/etc/ssl/private/ssl-cert-snakeoil.key',
    ssl_chain_file                  => '',
    ssh_dsa_key_contents            => $ssh_dsa_key_contents,
    ssh_dsa_pubkey_contents         => $ssh_dsa_pubkey_contents,
    ssh_rsa_key_contents            => $ssh_rsa_key_contents,
    ssh_rsa_pubkey_contents         => $ssh_rsa_pubkey_contents,
    ssh_project_rsa_key_contents    => $ssh_project_rsa_key_contents,
    ssh_project_rsa_pubkey_contents => $ssh_project_rsa_pubkey_contents,
    email                           => 'review-dev@openstack.org',
    war                             =>
      'http://tarballs.openstack.org/ci/gerrit-2.4.4-14-gab7f4c1.war',
    contactstore                    => true,
    contactstore_appsec             => $contactstore_appsec,
    contactstore_pubkey             => $contactstore_pubkey,
    contactstore_url                =>
      'https://review-dev.openstack.org/fakestore',
    script_user                     => 'launchpadsync',
    script_key_file                 => '/home/gerrit2/.ssh/launchpadsync_rsa',
    script_logging_conf             => '/home/gerrit2/.sync_logging.conf',
    projects_file                   =>
      'openstack_project/review-dev.projects.yaml.erb',
    github_username                 => 'openstack-gerrit-dev',
    github_oauth_token              => $github_oauth_token,
    github_project_username         => $github_project_username,
    github_project_password         => $github_project_password,
    mysql_password                  => $mysql_password,
    mysql_root_password             => $mysql_root_password,
    trivial_rebase_role_id          =>
      'trivial-rebase@review-dev.openstack.org',
    email_private_key               => $email_private_key,
    replicate_github                => $replicate_github,
    sysadmins                       => $sysadmins,
    swift_username                  => $swift_username,
    swift_password                  => $swift_password,
  }

  file { '/var/log/gerrit_user_sync':
    ensure  => directory,
    owner   => 'root',
    group   => 'gerrit2',
    mode    => '0775',
    require => User['gerrit2'],
  }
  file { '/home/gerrit2/.sync_logging.conf':
    ensure  => present,
    owner   => 'root',
    group   => 'gerrit2',
    mode    => '0644',
    source  =>
      'puppet:///modules/openstack_project/gerrit/launchpad_sync_logging.conf',
    require => User['gerrit2'],
  }
  file { '/home/gerrit2/.ssh':
    ensure  => directory,
    owner   => 'gerrit2',
    group   => 'gerrit2',
    mode    => '0700',
    require => User['gerrit2'],
  }
  if $lp_sync_key != '' {
    file { '/home/gerrit2/.ssh/launchpadsync_rsa':
      ensure  => present,
      owner   => 'gerrit2',
      group   => 'gerrit2',
      mode    => '0600',
      content => $lp_sync_key,
      replace => true,
      require => User['gerrit2'],
    }
  }
  if $lp_sync_pubkey != '' {
    file { '/home/gerrit2/.ssh/launchpadsync_rsa.pub':
      ensure  => present,
      owner   => 'gerrit2',
      group   => 'gerrit2',
      mode    => '0644',
      content => $lp_sync_pubkey,
      replace => true,
      require => User['gerrit2'],
    }
  }
  file { '/home/gerrit2/.launchpadlib':
    ensure  => directory,
    owner   => 'gerrit2',
    group   => 'gerrit2',
    mode    => '0775',
    require => User['gerrit2'],
  }
  file { '/home/gerrit2/.launchpadlib/creds':
    ensure  => present,
    owner   => 'gerrit2',
    group   => 'gerrit2',
    mode    => '0600',
    content => template('openstack_project/gerrit_lp_creds.erb'),
    replace => true,
    require => User['gerrit2'],
  }
}
