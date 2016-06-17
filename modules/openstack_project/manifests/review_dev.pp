# == Class: openstack_project::review_dev
#
class openstack_project::review_dev (
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
  # SSH key for outbound ssh-based replication.
  $ssh_replication_rsa_key_contents='',
  $ssh_replication_rsa_pubkey_contents='',
  $lp_sync_consumer_key = '',
  $lp_sync_token = '',
  $lp_sync_secret = '',
  $swift_username = '',
  $swift_password = '',
  $storyboard_username = '',
  $storyboard_password = '',
  $project_config_repo = '',
  $projects_config = 'openstack_project/review-dev.projects.ini.erb',
) {

  realize (
    User::Virtual::Localuser['zaro'],
  )

  class { 'project_config':
    url  => $project_config_repo,
    base => 'dev/',
  }

  class { 'openstack_project::gerrit':
    vhost_name                          => 'review-dev.openstack.org',
    canonicalweburl                     => 'https://review-dev.openstack.org/',
    ssl_cert_file                       => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
    ssl_key_file                        => '/etc/ssl/private/ssl-cert-snakeoil.key',
    ssl_chain_file                      => '',
    ssh_dsa_key_contents                => $ssh_dsa_key_contents,
    ssh_dsa_pubkey_contents             => $ssh_dsa_pubkey_contents,
    ssh_rsa_key_contents                => $ssh_rsa_key_contents,
    ssh_rsa_pubkey_contents             => $ssh_rsa_pubkey_contents,
    ssh_project_rsa_key_contents        => $ssh_project_rsa_key_contents,
    ssh_project_rsa_pubkey_contents     => $ssh_project_rsa_pubkey_contents,
    ssh_replication_rsa_key_contents    => $ssh_replication_rsa_key_contents,
    ssh_replication_rsa_pubkey_contents => $ssh_replication_rsa_pubkey_contents,
    email                               => 'review-dev@openstack.org',
    war                                 =>
      'http://tarballs.openstack.org/ci/gerrit/gerrit-v2.11.4.11.a14450f.war',
    contactstore                        => $contactstore,
    contactstore_appsec                 => $contactstore_appsec,
    contactstore_pubkey                 => $contactstore_pubkey,
    contactstore_url                    =>
      'https://review-dev.openstack.org/fakestore',
    acls_dir                            => $::project_config::gerrit_acls_dir,
    notify_impact_file                  => $::project_config::gerrit_notify_impact_file,
    projects_file                       => $::project_config::jeepyb_project_file,
    projects_config                     => $projects_config,
    github_username                     => 'openstack-gerrit-dev',
    github_oauth_token                  => $github_oauth_token,
    github_project_username             => $github_project_username,
    github_project_password             => $github_project_password,
    mysql_host                          => $mysql_host,
    mysql_password                      => $mysql_password,
    email_private_key                   => $email_private_key,
    gitweb                              => false,
    cgit                                => true,
    web_repo_url                        => 'https://git.openstack.org/cgit/',
    web_repo_url_encode                 => false,
    swift_username                      => $swift_username,
    swift_password                      => $swift_password,
    replication_force_update            => true,
    commentlinks                        => [
      {
        name  => 'bugheader',
        match => '([Cc]loses|[Pp]artial|[Rr]elated)-[Bb]ug:\\s*#?(\\d+)',
        link  => 'https://launchpad.net/bugs/$2',
      },
      {
        name  => 'bug',
        match => '\\b[Bb]ug:? #?(\\d+)',
        link  => 'https://launchpad.net/bugs/$1',
      },
      {
        name  => 'story',
        match => '\\b[Ss]tory:? #?(\\d+)',
        link  => 'https://storyboard-dev.openstack.org/#!/story/$1',
      },
      {
        name  => 'blueprint',
        match => '(\\b[Bb]lue[Pp]rint\\b|\\b[Bb][Pp]\\b)[ \\t#:]*([A-Za-z0-9\\-]+)',
        link  => 'https://blueprints.launchpad.net/openstack/?searchtext=$2',
      },
      {
        name  => 'testresult',
        match => '<li>([^ ]+) <a href=\"[^\"]+\" target=\"_blank\">([^<]+)</a> : ([^ ]+)([^<]*)</li>',
        html  => '<li class=\"comment_test\"><span class=\"comment_test_name\"><a href=\"$2\">$1</a></span> <span class=\"comment_test_result\"><span class=\"result_$3\">$3</span>$4</span></li>',
      },
      {
        name  => 'launchpadbug',
        match => '<a href=\"(https://bugs\\.launchpad\\.net/[a-zA-Z0-9\\-]+/\\+bug/(\\d+))[^\"]*\">[^<]+</a>',
        html  => '<a href=\"$1\">$1</a>'
      },
      {
        name  => 'changeid',
        match => '(I[0-9a-f]{8,40})',
        link  => '/#q,$1,n,z',
      },
      {
        name  => 'gitsha',
        match => '(<p>|[\\s(])([0-9a-f]{40})(</p>|[\\s.,;:)])',
        html  => '$1<a href=\"/#q,$2,n,z\">$2</a>$3',
      },
    ],
    its_plugins                        => [
      {
        name     => 'its-storyboard',
        username => $storyboard_username,
        password => $storyboard_password,
        url      => 'https://storyboard.openstack.org',
      },
    ],
    replication                         => [
      {
        name                 => 'github',
        url                  => 'git@github.com:',
        authGroup            => 'Anonymous Users',
        replicationDelay     => '1',
        replicatePermissions => false,
        mirror               => true,
      },
      {
        name                 => 'local',
        url                  => 'file:///opt/lib/git/',
        replicationDelay     => '1',
        threads              => '4',
        mirror               => true,
      },
      {
        name                 => 'afs',
        url                  => 'file:///afs/openstack.org/mirror/git-sandbox/',
        replicationDelay     => '1',
        threads              => '4',
        mirror               => true,
      },
    ],
    require                         => $::project_config::config_dir,
  }

  gerrit::plugin { 'javamelody':
    version => '3fefa35',
  }

  package { 'python-launchpadlib':
    ensure => present,
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
