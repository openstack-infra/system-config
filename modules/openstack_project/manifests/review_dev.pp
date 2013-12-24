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
  $lp_sync_consumer_key = '',
  $lp_sync_token = '',
  $lp_sync_secret = '',
  $sysadmins = [],
  $swift_username = '',
  $swift_password = ''
) {

  realize (
    User::Virtual::Localuser['zaro'],
  )

  # Setup MySQL
  class { 'gerrit::mysql':
    mysql_root_password  => $mysql_root_password,
    database_name        => 'reviewdb',
    database_user        => 'gerrit2',
    database_password    => $mysql_password,
  }

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
    trivial_rebase_role_id          =>
      'trivial-rebase@review-dev.openstack.org',
    mysql_password                  => $mysql_password,
    email_private_key               => $email_private_key,
    sysadmins                       => $sysadmins,
    gitweb                          => false,
    cgit                            => true,
    web_repo_url                    => 'https://git.openstack.org/cgit/',
    swift_username                  => $swift_username,
    swift_password                  => $swift_password,
    replication                     => [
      {
        name                 => 'github',
        url                  => 'git@github.com:',
        authGroup            => 'Anonymous Users',
        replicatePermissions => false,
        mirror               => true,
      },
      {
        name                 => 'local',
        url                  => 'file:///var/lib/git/',
        replicationDelay     => '0',
        threads              => '4',
        mirror               => true,
      },
    ],
  }

  file { '/home/gerrit2/.ssh':
    ensure  => directory,
    owner   => 'gerrit2',
    group   => 'gerrit2',
    mode    => '0700',
    require => User['gerrit2'],
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

  include bup
  bup::site { 'rs-ord':
    backup_user   => 'bup-review-dev',
    backup_server => 'ci-backup-rs-ord.openstack.org',
  }
}
