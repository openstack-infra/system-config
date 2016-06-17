# == Class: openstack_project::review

# Current thinking on Gerrit tuning parameters:

# database.poolLimit:
# This limit must be several units higher than the total number of
# httpd and sshd threads as some request processing code paths may need
# multiple connections.
# database.poolLimit = 1 + max(sshd.threads,sshd.batchThreads)
#   + sshd.streamThreads + sshd.commandStartThreads
#   + httpd.acceptorThreads + httpd.maxThreads
# http://groups.google.com/group/repo-discuss/msg/4c2809310cd27255
# or "2x sshd.threads"
# http://groups.google.com/group/repo-discuss/msg/269024c966e05d6a

# container.heaplimit:
# core.packedgit*
# http://groups.google.com/group/repo-discuss/msg/269024c966e05d6a

# sshd.threads:
# http:
#  //groups.google.com/group/repo-discuss/browse_thread/thread/b91491c185295a71

# httpd.maxQueued:
# Default value is too low, should increase to new default.
# https://gerrit-review.googlesource.com/#/c/70627

# httpd.maxWait:
# 12:07 <@spearce> httpd.maxwait defaults to 5 minutes and is how long gerrit
#                  waits for an idle sshd.thread before aboring the http request
# 12:08 <@spearce> ironically
# 12:08 <@spearce> ProjectQosFilter passes this value as minutes
# 12:08 <@spearce> to a method that accepts milliseconds
# 12:09 <@spearce> so. you get 5 milliseconds before aborting
# thus, set it to 5000minutes until the bug is fixed.
class openstack_project::review (
  # Created by running jeepyb ?
  $github_oauth_token = '',
  # Create a dedicated user e.g. openstack-project-creator, put
  # details here.
  $github_project_username = '',
  $github_project_password = '',
  # Create arbitrary values and put here, puppet will use during
  # provisioning.
  $mysql_host = '',
  $mysql_password = '',
  $email_private_key = '',
  $token_private_key = '',
  # Register an IRC bot and supply it's password here.
  $gerritbot_password = '',
  $gerritbot_ssh_rsa_key_contents = '',
  $gerritbot_ssh_rsa_pubkey_contents = '',
  # Register SSL keys and pass their contents in.
  $ssl_cert_file = "/etc/ssl/certs/${::fqdn}.pem",
  $ssl_cert_file_contents = '',
  $ssl_key_file = "/etc/ssl/private/${::fqdn}.key",
  $ssl_key_file_contents = '',
  $ssl_chain_file = '/etc/ssl/certs/intermediate.pem',
  $ssl_chain_file_contents = '',
  # Create SSH server key by hand and supply here.
  $ssh_dsa_key_contents = '',
  $ssh_dsa_pubkey_contents = '',
  $ssh_rsa_key_contents = '',
  $ssh_rsa_pubkey_contents='',
  # manage-projects's user ssh key.
  $ssh_project_rsa_key_contents='',
  $ssh_project_rsa_pubkey_contents='',
  # SSH key for outbound ssh-based replication.
  $ssh_replication_rsa_key_contents='',
  $ssh_replication_rsa_pubkey_contents='',
  # welcome-message's user ssh key.
  $ssh_welcome_rsa_key_contents='',
  $ssh_welcome_rsa_pubkey_contents='',
  # To be renamed - they're now just launchpad creds, not lp_sync
  $lp_sync_consumer_key='',
  $lp_sync_token='',
  $lp_sync_secret='',
  # For gerrit's contactstore feature
  # https://review.openstack.org/Documentation/config-contact.html
  $contactstore = true,
  $contactstore_appsec='',
  $contactstore_pubkey='',
  # For openstackwatch.
  $swift_username = '',
  $swift_password = '',
  $storyboard_username = '',
  $storyboard_password = '',
  $project_config_repo = '',
  $projects_config = 'openstack_project/review.projects.ini.erb',
) {

  $java_home = $::lsbdistcodename ? {
    'precise' => '/usr/lib/jvm/java-7-openjdk-amd64/jre',
    'trusty'  => '/usr/lib/jvm/java-7-openjdk-amd64/jre',
  }

  class { 'project_config':
    url  => $project_config_repo,
  }

  class { 'openstack_project::gerrit':
    git_http_url                        => 'https://git.openstack.org/',
    ssl_cert_file                       => $ssl_cert_file,
    ssl_key_file                        => $ssl_key_file,
    ssl_chain_file                      => $ssl_chain_file,
    ssl_cert_file_contents              => $ssl_cert_file_contents,
    ssl_key_file_contents               => $ssl_key_file_contents,
    ssl_chain_file_contents             => $ssl_chain_file_contents,
    ssh_dsa_key_contents                => $ssh_dsa_key_contents,
    ssh_dsa_pubkey_contents             => $ssh_dsa_pubkey_contents,
    ssh_rsa_key_contents                => $ssh_rsa_key_contents,
    ssh_rsa_pubkey_contents             => $ssh_rsa_pubkey_contents,
    ssh_project_rsa_key_contents        => $ssh_project_rsa_key_contents,
    ssh_project_rsa_pubkey_contents     => $ssh_project_rsa_pubkey_contents,
    ssh_replication_rsa_key_contents    => $ssh_replication_rsa_key_contents,
    ssh_replication_rsa_pubkey_contents => $ssh_replication_rsa_pubkey_contents,
    ssh_welcome_rsa_key_contents        => $ssh_welcome_rsa_key_contents,
    ssh_welcome_rsa_pubkey_contents     => $ssh_welcome_rsa_pubkey_contents,
    email                               => 'review@openstack.org',
      # 1 + 100 + 9 + 2 + 2 + 25 => 139(rounded up)
    database_poollimit                  => '150',
    container_heaplimit                 => '30g',
    core_packedgitopenfiles             => '4096',
    core_packedgitlimit                 => '400m',
    core_packedgitwindowsize            => '16k',
    sshd_threads                        => '100',
    index_threads                       => 4,
    httpd_maxqueued                     => '200',
    war                                 =>
      'http://tarballs.openstack.org/ci/gerrit/gerrit-v2.11.4.11.a14450f.war',
    contactstore                        => $contactstore,
    contactstore_appsec                 => $contactstore_appsec,
    contactstore_pubkey                 => $contactstore_pubkey,
    contactstore_url                    =>
      'http://direct.openstack.org/verify/member/',
    acls_dir                            => $::project_config::gerrit_acls_dir,
    notify_impact_file                  => $::project_config::gerrit_notify_impact_file,
    projects_file                       => $::project_config::jeepyb_project_file,
    projects_config                     => $projects_config,
    github_username                     => 'openstack-gerrit',
    github_oauth_token                  => $github_oauth_token,
    github_project_username             => $github_project_username,
    github_project_password             => $github_project_password,
    mysql_host                          => $mysql_host,
    mysql_password                      => $mysql_password,
    email_private_key                   => $email_private_key,
    token_private_key                   => $token_private_key,
    swift_username                      => $swift_username,
    swift_password                      => $swift_password,
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
        name  => 'its-storyboard',
        match => '\\b[Ss]tory:? #?(\\d+)',
        link  => 'https://storyboard.openstack.org/#!/story/$1',
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
        url      => 'https://storyboard-dev.openstack.org',
      },
    ],
    its_actions                        => [
      {
        name       => 'change_updates',
        event_type => 'patchset-created,change-abandoned,change-restored,change-merged',
        action     => 'add-standard-comment',
      },
    ],
    download                            => {
        'command' => ['checkout', 'cherry_pick', 'pull', 'format_patch'],
        'scheme'  => ['ssh', 'anon_http', 'anon_git'],
        'archive' => ['tar', 'tbz2', 'tgz', 'txz'],
    },
    replication_force_update            => true,
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
        name                 => 'git01',
        url                  => 'cgit@git01.openstack.org:/var/lib/git/',
        replicationDelay     => '1',
        threads              => '4',
        mirror               => true,
      },
      {
        name                 => 'git02',
        url                  => 'cgit@git02.openstack.org:/var/lib/git/',
        replicationDelay     => '1',
        threads              => '4',
        mirror               => true,
      },
      {
        name                 => 'git03',
        url                  => 'cgit@git03.openstack.org:/var/lib/git/',
        replicationDelay     => '1',
        threads              => '4',
        mirror               => true,
      },
      {
        name                 => 'git04',
        url                  => 'cgit@git04.openstack.org:/var/lib/git/',
        replicationDelay     => '1',
        threads              => '4',
        mirror               => true,
      },
      {
        name                 => 'git05',
        url                  => 'cgit@git05.openstack.org:/var/lib/git/',
        replicationDelay     => '1',
        threads              => '4',
        mirror               => true,
      },
      {
        name                 => 'git06',
        url                  => 'cgit@git06.openstack.org:/var/lib/git/',
        replicationDelay     => '1',
        threads              => '4',
        mirror               => true,
      },
      {
        name                 => 'git07',
        url                  => 'cgit@git07.openstack.org:/var/lib/git/',
        replicationDelay     => '1',
        threads              => '4',
        mirror               => true,
      },
      {
        name                 => 'git08',
        url                  => 'cgit@git08.openstack.org:/var/lib/git/',
        replicationDelay     => '1',
        threads              => '4',
        mirror               => true,
      },
    ],
    require                             => $::project_config::config_dir,
  }

  gerrit::plugin { 'javamelody':
    version => '3fefa35',
  }

  class { 'gerritbot':
    nick                    => 'openstackgerrit',
    password                => $gerritbot_password,
    server                  => 'irc.freenode.net',
    user                    => 'gerritbot',
    vhost_name              => $::fqdn,
    ssh_rsa_key_contents    => $gerritbot_ssh_rsa_key_contents,
    ssh_rsa_pubkey_contents => $gerritbot_ssh_rsa_pubkey_contents,
    channel_file            => $::project_config::gerritbot_channel_file,
    require                 => $::project_config::config_dir,
  }
  class { 'gerrit::remotes':
    ensure => absent,
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
    backup_user   => 'bup-review',
    backup_server => 'ci-backup-rs-ord.openstack.org',
  }
}
