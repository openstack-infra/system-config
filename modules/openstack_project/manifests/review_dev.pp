class openstack_project::review_dev (
  $github_oauth_token,
  $mysql_password,
  $mysql_root_password,
  $email_private_key,
  $sysadmins = []
) {
  class { 'openstack_project::gerrit':
    vhost_name => 'review-dev.openstack.org',
    canonicalweburl => "https://review-dev.openstack.org/",
    ssl_cert_file => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
    ssl_key_file => '/etc/ssl/private/ssl-cert-snakeoil.key',
    ssl_chain_file => '',
    email => "review-dev@openstack.org",
    war => 'http://tarballs.openstack.org/ci/gerrit-2.4.2-11-gb5a28fb.war',
    script_user => 'launchpadsync',
    script_key_file => '/home/gerrit2/.ssh/launchpadsync_rsa',
    script_logging_conf => '/home/gerrit2/.sync_logging.conf',
    projects_file => 'puppet:///openstack_project/review-dev.projects.yaml',
    github_username => 'openstack-gerrit-dev',
    github_oauth_token => $github_oauth_token,
    mysql_password => $mysql_password,
    mysql_root_password => $mysql_root_password,
    email_private_key => $email_private_key,
    sysadmins => $sysadmins
  }

  file { '/var/log/gerrit_user_sync':
    ensure => directory,
    owner => root,
    group => gerrit2,
    mode => 0775,
    require => User['gerrit2']
  }
  file { '/home/gerrit2/.sync_logging.conf':
    ensure => present,
    owner => root,
    group => gerrit2,
    mode => 0644,
    source => 'puppet:///modules/openstack_project/gerrit/launchpad_sync_logging.conf',
    require => User['gerrit2']
  }
}
