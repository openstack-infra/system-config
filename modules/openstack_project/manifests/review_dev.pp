# == Class: openstack_project::review_dev
#
class openstack_project::review_dev (
  $admin_users = [
    'zaro',
  ],
  $gerrit_canonicalweburl = 'https://review-dev.openstack.org/',
  $gerrit_contactstore_url = 'https://review-dev.openstack.org/fakestore',
  $gerrit_email = 'review-dev@openstack.org',
  $gerrit_github_username = 'openstack-gerrit-dev',
  $gerrit_plugins = {
    'javamelody' => { 'version' => 'e00d5af' },
  },
  $gerrit_vhost_name = 'review-dev.openstack.org',
  $gerrit_war = 'http://tarballs.openstack.org/ci/test/gerrit-v2.8.4.17.13ac409.war',
  $gerrit_web_repo_url = 'https://git.openstack.org/cgit/',
  $github_oauth_token = '',
  $github_project_username = '',
  $github_project_password = '',
  $mysql_host = '',
  $mysql_password = '',
  $email_private_key = '',
  $contactstore = true,
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
  $swift_password = '',
  $project_config_repo = '',
  $projects_config = 'openstack_project/review-dev.projects.ini.erb',
  $use_bup = true,
  $bup_backup_user = 'bup-review-dev',
  $bup_backup_server = 'ci-backup-rs-ord.openstack.org',
) {

  realize (
    User::Virtual::Localuser[$admin_users],
  )

  class { 'project_config':
    url  => $project_config_repo,
    base => 'dev/',
  }

  class { 'openstack_project::gerrit':
    vhost_name                      => $gerrit_vhost_name,
    canonicalweburl                 => $gerrit_canonicalweburl,
    ssl_cert_file                   => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
    ssl_key_file                    => '/etc/ssl/private/ssl-cert-snakeoil.key',
    ssl_chain_file                  => '',
    ssh_dsa_key_contents            => $ssh_dsa_key_contents,
    ssh_dsa_pubkey_contents         => $ssh_dsa_pubkey_contents,
    ssh_rsa_key_contents            => $ssh_rsa_key_contents,
    ssh_rsa_pubkey_contents         => $ssh_rsa_pubkey_contents,
    ssh_project_rsa_key_contents    => $ssh_project_rsa_key_contents,
    ssh_project_rsa_pubkey_contents => $ssh_project_rsa_pubkey_contents,
    email                           => $gerrit_email,
    war                             => $gerrit_war,
    contactstore                    => $contactstore,
    contactstore_appsec             => $contactstore_appsec,
    contactstore_pubkey             => $contactstore_pubkey,
    contactstore_url                => $gerrit_contactstore_url,
    acls_dir                        => $::project_config::gerrit_acls_dir,
    notify_impact_file              => $::project_config::gerrit_notify_impact_file,
    projects_file                   => $::project_config::jeepyb_project_file,
    projects_config                 => $projects_config,
    github_username                 => $gerrit_github_username,
    github_oauth_token              => $github_oauth_token,
    github_project_username         => $github_project_username,
    github_project_password         => $github_project_password,
    mysql_host                      => $mysql_host,
    mysql_password                  => $mysql_password,
    email_private_key               => $email_private_key,
    sysadmins                       => $sysadmins,
    gitweb                          => false,
    cgit                            => true,
    web_repo_url                    => $gerrit_web_repo_url,
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
        url                  => 'file:///opt/lib/git/',
        replicationDelay     => '0',
        threads              => '4',
        mirror               => true,
      },
    ],
    require                         => $::project_config::config_dir,
  }

  create_resources('gerrit::plugin',$gerrit_plugins)

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

  if $use_bup {
    include bup
    bup::site { 'rs-ord':
      backup_user   => $bup_backup_user,
      backup_server => $bup_backup_server,
    }
  }
}
