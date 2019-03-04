# == Class: openstack_project::review_dev
#
class openstack_project::review_dev (
  $github_oauth_token = '',
  $github_project_username = '',
  $github_project_password = '',
  $mysql_host = '',
  $mysql_password = '',
  $email_private_key = '',
  $ssh_dsa_key_contents = '',
  $ssh_dsa_pubkey_contents = '',
  $ssh_rsa_key_contents = '',
  $ssh_rsa_pubkey_contents = '',
  $ssh_project_rsa_key_contents = '',
  $ssh_project_rsa_pubkey_contents = '',
  # SSH key for outbound ssh-based replication.
  $ssh_replication_rsa_key_contents='',
  $ssh_replication_rsa_pubkey_contents='',
  # Launchpad creds for bug/blueprint updates
  $lp_access_token = '',
  $lp_access_secret = '',
  $lp_consumer_key = '',
  $swift_username = '',
  $swift_password = '',
  $storyboard_password = '',
  $storyboard_ssl_cert = '',
  $project_config_repo = '',
  $projects_config = 'openstack_project/review-dev.projects.ini.erb',
  $gerrit_configure = true,
) {

  case $::lsbdistcodename {
    'trusty': {
      $jre_package = 'openjdk-7-jre-headless'
      $java_home = '/usr/lib/jvm/java-7-openjdk-amd64/jre'
    }
    'xenial': {
      $jre_package = 'openjdk-8-jre-headless'
      $java_home = '/usr/lib/jvm/java-8-openjdk-amd64/jre'
    }
    default: {
      fail("Operating system release ${::lsbdistcodename} not supported.")
    }
  }

  class { 'project_config':
    url  => $project_config_repo,
    base => 'dev/',
  }

  if ($gerrit_configure) {
    $accountpatchreviewdb_url = "jdbc:mysql://${mysql_host}:3306/accountPatchReviewDb?characterSetResults=utf8&characterEncoding=utf8&connectionCollation=utf8_bin&useUnicode=yes&user=gerrit2&password=${mysql_password}"
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
        'https://tarballs.openstack.org/gerrit/gerrit-v2.13.12.11.1707fec.war',
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
      accountpatchreviewdb_url            => $accountpatchreviewdb_url,
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
          match => '([Cc]loses|[Pp]artial|[Rr]elated)-[Bb]ug:\\\\s*#?(\\\\d+)',
          link  => 'https://launchpad.net/bugs/$2',
        },
        {
          name  => 'bug',
          match => '\\\\b[Bb]ug:? #?(\\\\d+)',
          link  => 'https://launchpad.net/bugs/$1',
        },
        {
          name  => 'story',
          match => '\\\\b[Ss]tory:? #?(\\\\d+)',
          link  => 'https://storyboard-dev.openstack.org/#!/story/$1',
        },
        {
          name  => 'task',
          match => '\\\\b[Tt]ask:? #?(\\\\d+)',
          link  => 'https://storyboard-dev.openstack.org/#!/task/$1',
        },
        {
          name  => 'its-storyboard',
          match => '\\\\b[Tt]ask:? #?(\\\\d+)',
          link  => 'task: $1',
        },
        {
          name  => 'blueprint',
          match => '(\\\\b[Bb]lue[Pp]rint\\\\b|\\\\b[Bb][Pp]\\\\b)[ \\\\t#:]*([A-Za-z0-9\\\\-]+)',
          link  => 'https://blueprints.launchpad.net/openstack/?searchtext=$2',
        },
        {
          name  => 'testresult',
          match => '<li>([^ ]+) <a href=\"[^\"]+\" target=\"_blank\" rel=\"nofollow\">([^<]+)</a> : ([^ ]+)([^<]*)</li>',
          html  => '<li class=\"comment_test\"><span class=\"comment_test_name\"><a href=\"$2\" rel=\"nofollow\">$1</a></span> <span class=\"comment_test_result\"><span class=\"result_$3\">$3</span>$4</span></li>',
        },
        {
          name  => 'launchpadbug',
          match => '<a href=\"(https://bugs\\\\.launchpad\\\\.net/[a-zA-Z0-9\\\\.]+/\\\\+bug/(\\\\d+))[^\"]*\">[^<]+</a>',
          html  => '<a href=\"$1\">$1</a>'
        },
        {
          name  => 'changeid',
          match => '(I[0-9a-f]{8,40})',
          link  => '/#/q/$1',
        },
        {
          name  => 'gitsha',
          match => '(<p>|[\\\\s(])([0-9a-f]{40})(</p>|[\\\\s.,;:)])',
          html  => '$1<a href=\"/#/q/$2\">$2</a>$3',
        },
      ],
      its_plugins                        => [
        {
          name     => 'its-storyboard',
          password => $storyboard_password,
          url      => 'https://storyboard-dev.openstack.org',
        },
      ],
      # See https://gerrit.googlesource.com/plugins/its-storyboard
      #   /+/stable-2.13/src/main/resources/Documentation
      #   /quick-install-guide.md#its_actions_its_actionsconfigure-its-actions
      # for documentation on these options.
      its_rules                          => [
        {
          name       => 'LOG',
          action     => 'log-event error',
        },
        {
          name       => 'comment-on-status-update',
          event_type => 'patchset-created,change-abandoned,change-restored,change-merged',
          action     => 'add-standard-comment',
        },
        {
          name       => 'change_abandoned',
          event_type => 'change-abandoned',
          action     => 'set-status TODO',
        },
        {
          name       => 'change_in_progress',
          event_type => 'patchset-created,change-restored',
          action     => 'set-status REVIEW',
        },
        {
          name       => 'change_merged',
          event_type => 'change-merged',
          action     => 'set-status MERGED',
        },
      ],
      replication                         => [
        {
          name                 => 'github',
          url                  => 'ssh://git@github.com:22/',
          authGroup            => 'Anonymous Users',
          replicationDelay     => '1',
          replicatePermissions => false,
          mirror               => true,
          projects             => [
            'gtest-org/*',
            'kdc*',
          ]
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

    gerrit::plugin { 'javamelody': version       => 'v2.13.3.e4233d6' }
    gerrit::plugin { 'its-storyboard': version   => '805f9ac' }


    # create a file containing the ssl certificate
    file { '/home/gerrit2/storyboard-dev.crt':
      ensure  => present,
      owner   => 'gerrit2',
      group   => 'gerrit2',
      mode    => '0600',
      content => $storyboard_ssl_cert,
      replace => true,
      require => User['gerrit2'],
    }

    # Import certificate to java to allow gerrit its plugins to POST to storyboard
    exec { 'import-java-certs':
      user        => 'root',
      command     => "keytool -import -alias storyboard-dev.openstack.org -keystore $java_home/lib/security/cacerts -file /home/gerrit2/storyboard-dev.crt -storepass changeit -noprompt",
      unless      => "keytool -list -alias storyboard-dev.openstack.org -storepass changeit -keystore $java_home/lib/security/cacerts  >/dev/null 2>&1",
      path        => '/bin:/usr/bin',
      require     => [
        Package[$jre_package],
        File['/home/gerrit2/storyboard-dev.crt'],
      ],
    }
  } else {
    # Only create gerrit user / group so we can bring a server online.
    include ::gerrit::user
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
    content => template('openstack_project/infra_lp_creds.erb'),
    replace => true,
    require => User['gerrit2'],
  }

  include bup
  bup::site { 'ord.rax':
    backup_user   => 'bup-review-dev',
    backup_server => 'backup01.ord.rax.ci.openstack.org',
  }
}
