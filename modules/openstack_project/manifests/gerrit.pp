# == Class: openstack_project::gerrit
#
# A wrapper class around the main gerrit class that sets gerrit
# up for launchpad single sign on and bug/blueprint links

class openstack_project::gerrit (
  $mysql_host,
  $mysql_password,
  $accountpatchreviewdb_url = undef,
  $vhost_name = $::fqdn,
  $canonicalweburl = "https://${::fqdn}/",
  $git_http_url = '',
  $canonical_git_url = '',
  $serveradmin = 'webmaster@openstack.org',
  $ssh_host_key = '/home/gerrit2/review_site/etc/ssh_host_rsa_key',
  $ssh_project_key = '/home/gerrit2/review_site/etc/ssh_project_rsa_key',
  $ssl_cert_file = "/etc/ssl/certs/${::fqdn}.pem",
  $ssl_key_file = "/etc/ssl/private/${::fqdn}.key",
  $ssl_chain_file = '/etc/ssl/certs/intermediate.pem',
  $ssl_cert_file_contents = '',
  $ssl_key_file_contents = '',
  $ssl_chain_file_contents = '',
  $ssh_dsa_key_contents = '', # If left empty puppet will not create file.
  $ssh_dsa_pubkey_contents = '', # If left empty puppet will not create file.
  $ssh_rsa_key_contents = '', # If left empty puppet will not create file.
  $ssh_rsa_pubkey_contents = '', # If left empty puppet will not create file.
  $ssh_project_rsa_key_contents = '', # If left empty will not create file.
  $ssh_project_rsa_pubkey_contents = '', # If left empty will not create file.
  $ssh_welcome_rsa_key_contents='', # If left empty will not create file.
  $ssh_welcome_rsa_pubkey_contents='', # If left empty will not create file.
  $ssh_replication_rsa_key_contents='', # If left empty will not create file.
  $ssh_replication_rsa_pubkey_contents='', # If left empty will not create file.
  $email = '',
  $database_poollimit = '',
  $container_heaplimit = '',
  $core_packedgitopenfiles = '',
  $core_packedgitlimit = '',
  $core_packedgitwindowsize = '',
  $sshd_threads = '',
  $httpd_acceptorthreads = '',
  $httpd_minthreads = '',
  $httpd_maxthreads = '',
  $httpd_maxqueued = '',
  $httpd_maxwait = '',
  $war = '',
  $acls_dir = 'UNDEF',
  $notify_impact_file = 'UNDEF',
  $projects_file = 'UNDEF',
  $projects_config = 'UNDEF',
  $github_username = '',
  $github_oauth_token = '',
  $github_project_username = '',
  $github_project_password = '',
  $email_private_key = '',
  $token_private_key = '',
  $replicate_local = true,
  $replication_force_update = true,
  $replication_auto_reload = false,
  $replication = [],
  $local_git_dir = '/opt/lib/git',
  $jeepyb_cache_dir = '/opt/lib/jeepyb',
  $cla_description = 'OpenStack Individual Contributor License Agreement',
  $cla_file = 'static/cla.html',
  $cla_id = '2',
  $cla_name = 'ICLA',
  $testmode = false,
  $swift_username = '',
  $swift_password = '',
  $gitweb = false,
  $cgit = true,
  $web_repo_url = 'https://git.openstack.org/cgit/',
  $web_repo_url_encode = false,
  $secondary_index = true,
  $report_bug_text = 'Get Help',
  $report_bug_url = 'https://docs.openstack.org/infra/system-config/project.html#contributing',
  $index_threads = 1,
  $download = {},
  $receive_max_object_size_limit = '100 m',
  $cache_accounts = 32768,
  $cache_accounts_byemail = 32768,
  $cache_accounts_byname = 32768,
  $cache_groups_byuuid = 32768,
  $commentlinks = [],
  $commitmessage_params = {},
  $its_plugins = [],
  $its_rules = [],
  $java_home = '',
  $openidssourl = 'https://login.ubuntu.com/+openid',
) {

  class { 'jeepyb::openstackwatch':
    projects       => [
      'openstack/ceilometer',
      'openstack/cinder',
      'openstack/glance',
      'openstack/heat',
      'openstack/horizon',
      'openstack/infra',
      'openstack/keystone',
      'openstack/nova',
      'openstack/oslo',
      'openstack/neutron',
      'openstack/swift',
      'openstack/tempest',
      'openstack-dev/devstack',
    ],
    container      => 'rss',
    json_url       => 'https://review.openstack.org/query?q=status:open',
    swift_username => $swift_username,
    swift_password => $swift_password,
    swift_auth_url => 'https://auth.api.rackspacecloud.com/v1.0',
    auth_version   => '1.0',
  }

  class { '::gerrit':
    vhost_name                          => $vhost_name,
    canonicalweburl                     => $canonicalweburl,
    git_http_url                        => $git_http_url,
    canonical_git_url                   => $canonical_git_url,
    # opinions
    allow_drafts                        => false,
    enable_melody                       => true,
    melody_session                      => true,
    robots_txt_source                   => 'puppet:///modules/openstack_project/gerrit/robots.txt',
    enable_javamelody_top_menu          => false,
    # passthrough
    java_home                           => $java_home,
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
    email                               => $email,
    openidssourl                        => $openidssourl,
    database_poollimit                  => $database_poollimit,
    container_heaplimit                 => $container_heaplimit,
    core_packedgitopenfiles             => $core_packedgitopenfiles,
    core_packedgitlimit                 => $core_packedgitlimit,
    core_packedgitwindowsize            => $core_packedgitwindowsize,
    sshd_threads                        => $sshd_threads,
    httpd_acceptorthreads               => $httpd_acceptorthreads,
    httpd_minthreads                    => $httpd_minthreads,
    httpd_maxthreads                    => $httpd_maxthreads,
    httpd_maxqueued                     => $httpd_maxqueued,
    httpd_maxwait                       => $httpd_maxwait,
    commentlinks                        => $commentlinks,
    its_plugins                         => $its_plugins,
    its_rules                           => $its_rules,
    trackingids                         => [
      {
        name    => 'launchpad-bug',
        footers => ['closes-bug:', 'partial-bug:', 'related-bug:'],
        match   => '\\\\#?(\\\\d+)',
        system  => 'Launchpad',
      },
      {
        name   => 'storyboard-story',
        footer => 'story:',
        match  => '\\\\#?(\\\\d+)',
        system => 'Storyboard',
      },
      {
        name   => 'storyboard-task',
        footer => 'task:',
        match  => '\\\\#?(\\\\d+)',
        system => 'Storyboard',
      },
    ],
    war                                 => $war,
    mysql_host                          => $mysql_host,
    mysql_password                      => $mysql_password,
    accountpatchreviewdb_url            => $accountpatchreviewdb_url,
    email_private_key                   => $email_private_key,
    token_private_key                   => $token_private_key,
    replicate_local                     => $replicate_local,
    replicate_path                      => $local_git_dir,
    replication_force_update            => $replication_force_update,
    replication_auto_reload             => $replication_auto_reload,
    replication                         => $replication,
    gitweb                              => $gitweb,
    cgit                                => $cgit,
    web_repo_url                        => $web_repo_url,
    web_repo_url_encode                 => $web_repo_url_encode,
    testmode                            => $testmode,
    secondary_index                     => $secondary_index,
    require                             => Class[openstack_project::server],
    report_bug_text                     => $report_bug_text,
    report_bug_url                      => $report_bug_url,
    index_threads                       => $index_threads,
    download                            => $download,
    receive_max_object_size_limit       => $receive_max_object_size_limit,
    commitmessage_params                =>
      {
        maxLineLength   => '72',
      },
    cache_accounts                      => $cache_accounts,
    cache_accounts_byemail              => $cache_accounts_byemail,
    cache_accounts_byname               => $cache_accounts_byname,
    cache_groups_byuuid                 => $cache_groups_byuuid,
  }

  mysql_backup::backup_remote { 'gerrit':
    database_host     => $mysql_host,
    database_user     => 'gerrit2',
    database_password => $mysql_password,
    dest_dir          => '/home/gerrit2/mysql_backups',
    num_backups       => '10',
    require           => Class['::gerrit'],
  }

  if ($testmode == false) {
    class { 'gerrit::cron':
      gitgc_repos      => true,
    }
    class { 'github':
      username         => $github_username,
      project_username => $github_project_username,
      project_password => $github_project_password,
      oauth_token      => $github_oauth_token,
      require          => Class['::gerrit']
    }
  }

  file { '/home/gerrit2/review_site/static/cla.html':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    source  => 'puppet:///modules/openstack_project/gerrit/cla.html',
    replace => true,
    require => Class['::gerrit'],
  }

  file { '/home/gerrit2/review_site/static/usg-cla.html':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    source  => 'puppet:///modules/openstack_project/gerrit/usg-cla.html',
    replace => true,
    require => Class['::gerrit'],
  }

  file { '/home/gerrit2/review_site/static/system-cla.html':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    source  => 'puppet:///modules/openstack_project/gerrit/system-cla.html',
    replace => true,
    require => Class['::gerrit'],
  }

  file { '/home/gerrit2/review_site/static/title.svg':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/openstack.svg',
    require => Class['::gerrit'],
    notify => Exec['reload_gerrit_header'],
  }

  package { 'libjs-jquery':
    ensure => present,
  }

  file { '/home/gerrit2/review_site/static/jquery.js':
    ensure  => present,
    source  => '/usr/share/javascript/jquery/jquery.js',
    require     => [
        File['/home/gerrit2/review_site/static'],
        Class['::gerrit'],
        Package['libjs-jquery'],
      ],
    subscribe   => Package['libjs-jquery'],
    notify      => Exec['reload_gerrit_header'],
  }

  vcsrepo { '/opt/jquery-visibility':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://github.com/mathiasbynens/jquery-visibility.git',
  }

  file { '/home/gerrit2/review_site/static/jquery-visibility.js':
    ensure => present,
    source => '/opt/jquery-visibility/jquery-visibility.js',
    subscribe => Vcsrepo['/opt/jquery-visibility'],
    notify => Exec['reload_gerrit_header'],
    require => [ File['/home/gerrit2/review_site/static'],
                 Class['::gerrit'] ]
  }

  file { '/home/gerrit2/review_site/static/hideci.js':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/gerrit/hideci.js',
    require => Class['::gerrit'],
    notify => Exec['reload_gerrit_header'],
  }

  file { '/home/gerrit2/review_site/etc/GerritSite.css':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/gerrit/GerritSite.css',
    require => Class['::gerrit'],
  }

  file { '/home/gerrit2/review_site/etc/GerritSiteHeader.html':
    ensure  => present,
    source  =>
      'puppet:///modules/openstack_project/gerrit/GerritSiteHeader.html',
    require => Class['::gerrit'],
  }

  exec { 'reload_gerrit_header':
    command     => 'sleep 10; touch /home/gerrit2/review_site/etc/GerritSiteHeader.html',
    path        => '/bin:/usr/bin',
    refreshonly => true,
  }

  cron { 'gerritsyncusers':
    ensure => absent,
  }

  cron { 'sync_launchpad_users':
    ensure => absent,
  }

  file { '/home/gerrit2/review_site/hooks/change-merged':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    source  => 'puppet:///modules/openstack_project/gerrit/change-merged',
    replace => true,
    require => Class['::gerrit'],
  }

  file { '/home/gerrit2/review_site/hooks/change-abandoned':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    source  => 'puppet:///modules/openstack_project/gerrit/change-abandoned',
    replace => true,
    require => Class['::gerrit'],
  }

  if ($notify_impact_file != 'UNDEF') {
    file { '/home/gerrit2/review_site/hooks/notify_impact.yaml':
      ensure  => present,
      source  => $notify_impact_file,
      require => Class['::gerrit'],
    }
  }

  file { '/home/gerrit2/review_site/hooks/patchset-created':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    content => template('openstack_project/gerrit_patchset-created.erb'),
    replace => true,
    require => Class['::gerrit'],
  }

  if $ssh_welcome_rsa_key_contents != '' {
    file { '/home/gerrit2/review_site/etc/ssh_welcome_rsa_key':
      owner   => 'gerrit2',
      group   => 'gerrit2',
      mode    => '0600',
      content => $ssh_welcome_rsa_key_contents,
      replace => true,
      require => File['/home/gerrit2/review_site/etc']
    }
  }

  if $ssh_welcome_rsa_pubkey_contents != '' {
    file { '/home/gerrit2/review_site/etc/ssh_welcome_rsa_key.pub':
      owner   => 'gerrit2',
      group   => 'gerrit2',
      mode    => '0644',
      content => $ssh_welcome_rsa_pubkey_contents,
      replace => true,
      require => File['/home/gerrit2/review_site/etc']
    }
  }

  if ($projects_file != 'UNDEF') {
    if ($replicate_local) {
      if (!defined(File[$local_git_dir])) {
        file { $local_git_dir:
          ensure  => directory,
          owner   => 'gerrit2',
          require => Class['::gerrit'],
        }
        cron { 'mirror_repack':
          ensure      => absent,
          user        => 'gerrit2',
        }
        cron { 'mirror_gitgc':
          user        => 'gerrit2',
          weekday     => '0',
          hour        => '4',
          minute      => '7',
          command     => "find ${local_git_dir} -type d -name \"*.git\" -print -exec git --git-dir=\"{}\" gc \\;",
          environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
        }
      }
    }

    file { '/home/gerrit2/projects.yaml':
      ensure  => present,
      owner   => 'gerrit2',
      group   => 'gerrit2',
      mode    => '0444',
      source  => $projects_file,
      replace => true,
      require => Class['::gerrit'],
    }

    file { $jeepyb_cache_dir:
      ensure => 'directory',
      owner  => 'gerrit2',
      group  => 'gerrit2',
      mode   => '0755',
    }

    file { '/home/gerrit2/projects.ini':
      ensure  => present,
      owner   => 'gerrit2',
      group   => 'gerrit2',
      mode    => '0444',
      content => template($projects_config),
      replace => true,
      require => Class['::gerrit'],
    }

    file { '/home/gerrit2/acls':
      ensure  => directory,
      owner   => 'gerrit2',
      group   => 'gerrit2',
      mode    => '0444',
      recurse => true,
      replace => true,
      purge   => true,
      force   => true,
      source  => $acls_dir,
      require => Class['::gerrit']
    }

    if ($testmode == false) {
      exec { 'manage_projects':
        command     => '/usr/local/bin/manage-projects -v -l /var/log/manage_projects.log',
        timeout     => 1800, # 30 minutes
        subscribe   => [
            File['/home/gerrit2/projects.yaml'],
            File['/home/gerrit2/acls'],
          ],
        refreshonly => true,
        logoutput   => true,
        require     => [
            File['/home/gerrit2/projects.yaml'],
            File['/home/gerrit2/acls'],
            Class['jeepyb'],
          ],
      }
      cron { 'track_upstream':
        user        => 'root',
        hour        => '*',
        minute      => '42',
        command     => '/usr/local/bin/track-upstream -v -l /var/log/track_upstream.log',
        environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
        require     => [
            File['/home/gerrit2/projects.yaml'],
            Class['jeepyb'],
        ],
      }

      include logrotate
      logrotate::file { 'manage_projects.log':
        log     => '/var/log/manage_projects.log',
        options => [
          'compress',
          'missingok',
          'rotate 30',
          'daily',
          'notifempty',
          'copytruncate',
        ],
        require => Exec['manage_projects'],
      }

      logrotate::file { 'track_upstream.log':
        log     => '/var/log/track_upstream.log',
        options => [
          'compress',
          'missingok',
          'rotate 30',
          'daily',
          'notifempty',
          'copytruncate',
        ],
        require => Cron['track_upstream'],
      }
    }
  }
  file { '/home/gerrit2/review_site/bin/set_agreements.sh':
    ensure  => absent,
  }
}
