#
# Top-level variables
#
# There must not be any whitespace between this comment and the variables or
# in between any two variables in order for them to be correctly parsed and
# passed around in test.sh
#
# Note we do not do a hiera lookup here as we set $group on a per node basis
# and that must be set before we can do hiera lookups. Doing a hiera lookup
# here would fail to find any group specific info.
$elasticsearch_nodes = [
  "elasticsearch02.openstack.org",
  "elasticsearch03.openstack.org",
  "elasticsearch04.openstack.org",
  "elasticsearch05.openstack.org",
  "elasticsearch06.openstack.org",
  "elasticsearch07.openstack.org",
]

#
# Default: should at least behave like an openstack server
#
node default {
  class { 'openstack_project::server':
  }
}

#
# Long lived servers:
#
# Node-OS: xenial
node /^review\d*\.open.*\.org$/ {
  $group = "review"

  class { 'openstack_project::server': }

  class { 'openstack_project::review':
    project_config_repo                 => 'https://git.openstack.org/openstack-infra/project-config',
    github_oauth_token                  => hiera('gerrit_github_token'),
    github_project_username             => hiera('github_project_username', 'username'),
    github_project_password             => hiera('github_project_password'),
    mysql_host                          => hiera('gerrit_mysql_host', 'localhost'),
    mysql_password                      => hiera('gerrit_mysql_password'),
    email_private_key                   => hiera('gerrit_email_private_key'),
    token_private_key                   => hiera('gerrit_rest_token_private_key'),
    gerritbot_password                  => hiera('gerrit_gerritbot_password'),
    gerritbot_ssh_rsa_key_contents      => hiera('gerritbot_ssh_rsa_key_contents'),
    gerritbot_ssh_rsa_pubkey_contents   => hiera('gerritbot_ssh_rsa_pubkey_contents'),
    ssl_cert_file_contents              => hiera('gerrit_ssl_cert_file_contents'),
    ssl_key_file_contents               => hiera('gerrit_ssl_key_file_contents'),
    ssl_chain_file_contents             => hiera('gerrit_ssl_chain_file_contents'),
    ssh_dsa_key_contents                => hiera('gerrit_ssh_dsa_key_contents'),
    ssh_dsa_pubkey_contents             => hiera('gerrit_ssh_dsa_pubkey_contents'),
    ssh_rsa_key_contents                => hiera('gerrit_ssh_rsa_key_contents'),
    ssh_rsa_pubkey_contents             => hiera('gerrit_ssh_rsa_pubkey_contents'),
    ssh_project_rsa_key_contents        => hiera('gerrit_project_ssh_rsa_key_contents'),
    ssh_project_rsa_pubkey_contents     => hiera('gerrit_project_ssh_rsa_pubkey_contents'),
    ssh_welcome_rsa_key_contents        => hiera('welcome_message_gerrit_ssh_private_key'),
    ssh_welcome_rsa_pubkey_contents     => hiera('welcome_message_gerrit_ssh_public_key'),
    ssh_replication_rsa_key_contents    => hiera('gerrit_replication_ssh_rsa_key_contents'),
    ssh_replication_rsa_pubkey_contents => hiera('gerrit_replication_ssh_rsa_pubkey_contents'),
    lp_access_token                     => hiera('gerrit_lp_access_token'),
    lp_access_secret                    => hiera('gerrit_lp_access_secret'),
    lp_consumer_key                     => hiera('gerrit_lp_consumer_key'),
    swift_username                      => hiera('swift_store_user', 'username'),
    swift_password                      => hiera('swift_store_key'),
    storyboard_password                 => hiera('gerrit_storyboard_token'),
  }
}

# Node-OS: xenial
node /^review-dev\d*\.open.*\.org$/ {
  $group = "review-dev"

  class { 'openstack_project::server':
    afs                       => true,
  }

  class { 'openstack_project::review_dev':
    project_config_repo                 => 'https://git.openstack.org/openstack-infra/project-config',
    github_oauth_token                  => hiera('gerrit_dev_github_token'),
    github_project_username             => hiera('github_dev_project_username', 'username'),
    github_project_password             => hiera('github_dev_project_password'),
    mysql_host                          => hiera('gerrit_dev_mysql_host', 'localhost'),
    mysql_password                      => hiera('gerrit_dev_mysql_password'),
    email_private_key                   => hiera('gerrit_dev_email_private_key'),
    ssh_dsa_key_contents                => hiera('gerrit_dev_ssh_dsa_key_contents'),
    ssh_dsa_pubkey_contents             => hiera('gerrit_dev_ssh_dsa_pubkey_contents'),
    ssh_rsa_key_contents                => hiera('gerrit_dev_ssh_rsa_key_contents'),
    ssh_rsa_pubkey_contents             => hiera('gerrit_dev_ssh_rsa_pubkey_contents'),
    ssh_project_rsa_key_contents        => hiera('gerrit_dev_project_ssh_rsa_key_contents'),
    ssh_project_rsa_pubkey_contents     => hiera('gerrit_dev_project_ssh_rsa_pubkey_contents'),
    ssh_replication_rsa_key_contents    => hiera('gerrit_dev_replication_ssh_rsa_key_contents'),
    ssh_replication_rsa_pubkey_contents => hiera('gerrit_dev_replication_ssh_rsa_pubkey_contents'),
    lp_access_token                     => hiera('gerrit_dev_lp_access_token'),
    lp_access_secret                    => hiera('gerrit_dev_lp_access_secret'),
    lp_consumer_key                     => hiera('gerrit_dev_lp_consumer_key'),
    storyboard_password                 => hiera('gerrit_dev_storyboard_token'),
    storyboard_ssl_cert                 => hiera('gerrit_dev_storyboard_ssl_crt'),
  }
}

# Node-OS: xenial
node /^grafana\d*\.open.*\.org$/ {
  $group = "grafana"
  class { 'openstack_project::server': }
  class { 'openstack_project::grafana':
    admin_password      => hiera('grafana_admin_password'),
    admin_user          => hiera('grafana_admin_user', 'username'),
    mysql_host          => hiera('grafana_mysql_host', 'localhost'),
    mysql_name          => hiera('grafana_mysql_name'),
    mysql_password      => hiera('grafana_mysql_password'),
    mysql_user          => hiera('grafana_mysql_user', 'username'),
    project_config_repo => 'https://git.openstack.org/openstack-infra/project-config',
    secret_key          => hiera('grafana_secret_key'),
  }
}

# Node-OS: xenial
node /^health\d*\.openstack\.org$/ {
  $group = "health"
  class { 'openstack_project::server': }
  class { 'openstack_project::openstack_health_api':
    subunit2sql_db_host => hiera('subunit2sql_db_host', 'localhost'),
    hostname            => 'health.openstack.org',
  }
}

# Node-OS: xenial
node /^cacti\d+\.open.*\.org$/ {
  $group = "cacti"
  include openstack_project::ssl_cert_check
  class { 'openstack_project::cacti':
    cacti_hosts => hiera_array('cacti_hosts'),
    vhost_name  => 'cacti.openstack.org',
  }
}

# Node-OS: xenial
node /^graphite\d*\.open.*\.org$/ {
  class { 'openstack_project::server': }

  class { '::graphite':
    graphite_admin_user     => hiera('graphite_admin_user', 'username'),
    graphite_admin_email    => hiera('graphite_admin_email', 'email@example.com'),
    graphite_admin_password => hiera('graphite_admin_password'),
    # NOTE(ianw): installed on the host via ansible
    ssl_cert_file           => '/etc/letsencrypt-certs/graphite01.opendev.org/graphite01.opendev.org.cer',
    ssl_key_file            => '/etc/letsencrypt-certs/graphite01.opendev.org/graphite01.opendev.org.key',
    ssl_chain_file          => '/etc/letsencrypt-certs/graphite01.opendev.org/ca.cer',
  }
}

# Node-OS: trusty
# Node-OS: xenial
node /^groups\d*\.open.*\.org$/ {
  class { 'openstack_project::server': }
  class { 'openstack_project::groups':
    site_admin_password          => hiera('groups_site_admin_password'),
    site_mysql_host              => hiera('groups_site_mysql_host', 'localhost'),
    site_mysql_password          => hiera('groups_site_mysql_password'),
    conf_cron_key                => hiera('groups_conf_cron_key'),
    site_ssl_cert_file_contents  => hiera('groups_site_ssl_cert_file_contents', undef),
    site_ssl_key_file_contents   => hiera('groups_site_ssl_key_file_contents', undef),
    site_ssl_chain_file_contents => hiera('groups_site_ssl_chain_file_contents', undef),
  }
}

# Node-OS: trusty
# Node-OS: xenial
node /^groups-dev\d*\.open.*\.org$/ {
  class { 'openstack_project::server': }
  class { 'openstack_project::groups_dev':
    site_admin_password          => hiera('groups_dev_site_admin_password'),
    site_mysql_host              => hiera('groups_dev_site_mysql_host', 'localhost'),
    site_mysql_password          => hiera('groups_dev_site_mysql_password'),
    conf_cron_key                => hiera('groups_dev_conf_cron_key'),
    site_ssl_cert_file_contents  => hiera('groups_dev_site_ssl_cert_file_contents', undef),
    site_ssl_key_file_contents   => hiera('groups_dev_site_ssl_key_file_contents', undef),
    site_ssl_cert_file           => '/etc/ssl/certs/groups-dev.openstack.org.pem',
    site_ssl_key_file            => '/etc/ssl/private/groups-dev.openstack.org.key',
  }
}

# Node-OS: trusty
# Node-OS: xenial
node /^lists\d*\.open.*\.org$/ {
  class { 'openstack_project::server': }

  class { 'openstack_project::lists':
    listpassword => hiera('listpassword'),
  }
}

# Node-OS: xenial
node /^lists\d*\.katacontainers\.io$/ {
  class { 'openstack_project::server': }

  class { 'openstack_project::kata_lists':
    listpassword => hiera('listpassword'),
  }
}

# Node-OS: xenial
node /^paste\d*\.open.*\.org$/ {
  $group = "paste"

  class { 'openstack_project::server': }
  class { 'openstack_project::paste':
    db_password         => hiera('paste_db_password'),
    db_host             => hiera('paste_db_host'),
    vhost_name          => 'paste.openstack.org',
  }
}

# Node-OS: xenial
node /planet\d*\.open.*\.org$/ {
  class { 'openstack_project::planet':
  }
}

# Node-OS: xenial
node /^eavesdrop\d*\.open.*\.org$/ {
  $group = "eavesdrop"
  class { 'openstack_project::server': }

  class { 'openstack_project::eavesdrop':
    project_config_repo     => 'https://git.openstack.org/openstack-infra/project-config',
    nickpass                => hiera('openstack_meetbot_password'),
    statusbot_nick          => hiera('statusbot_nick', 'username'),
    statusbot_password      => hiera('statusbot_nick_password'),
    statusbot_server        => 'chat.freenode.net',
    statusbot_channels      => hiera_array('statusbot_channels', ['openstack_infra']),
    statusbot_auth_nicks    => hiera_array('statusbot_auth_nicks'),
    statusbot_wiki_user     => hiera('statusbot_wiki_username', 'username'),
    statusbot_wiki_password => hiera('statusbot_wiki_password'),
    statusbot_wiki_url      => 'https://wiki.openstack.org/w/api.php',
    # https://wiki.openstack.org/wiki/Infrastructure_Status
    statusbot_wiki_pageid   => '1781',
    statusbot_wiki_successpageid => '7717',
    statusbot_wiki_successpageurl => 'https://wiki.openstack.org/wiki/Successes',
    statusbot_wiki_thankspageid => '37700',
    statusbot_wiki_thankspageurl => 'https://wiki.openstack.org/wiki/Thanks',
    statusbot_irclogs_url   => 'http://eavesdrop.openstack.org/irclogs/%(chan)s/%(chan)s.%(date)s.log.html',
    statusbot_twitter                 => true,
    statusbot_twitter_key             => hiera('statusbot_twitter_key'),
    statusbot_twitter_secret          => hiera('statusbot_twitter_secret'),
    statusbot_twitter_token_key       => hiera('statusbot_twitter_token_key'),
    statusbot_twitter_token_secret    => hiera('statusbot_twitter_token_secret'),
    accessbot_nick          => hiera('accessbot_nick', 'username'),
    accessbot_password      => hiera('accessbot_nick_password'),
    meetbot_channels        => hiera('meetbot_channels', ['openstack-infra']),
    ptgbot_nick             => hiera('ptgbot_nick', 'username'),
    ptgbot_password         => hiera('ptgbot_password'),
  }
}

# Node-OS: xenial
node /^ethercalc\d+\.open.*\.org$/ {
  $group = "ethercalc"
  class { 'openstack_project::server': }

  class { 'openstack_project::ethercalc':
    vhost_name              => 'ethercalc.openstack.org',
    ssl_cert_file_contents  => hiera('ssl_cert_file_contents'),
    ssl_key_file_contents   => hiera('ssl_key_file_contents'),
    ssl_chain_file_contents => hiera('ssl_chain_file_contents'),
  }
}

# Node-OS: xenial
node /^etherpad\d*\.open.*\.org$/ {
  $group = "etherpad"
  class { 'openstack_project::server': }

  class { 'openstack_project::etherpad':
    vhost_name              => 'etherpad.openstack.org',
    ssl_cert_file_contents  => hiera('etherpad_ssl_cert_file_contents'),
    ssl_key_file_contents   => hiera('etherpad_ssl_key_file_contents'),
    ssl_chain_file_contents => hiera('etherpad_ssl_chain_file_contents'),
    mysql_host              => hiera('etherpad_db_host', 'localhost'),
    mysql_user              => hiera('etherpad_db_user', 'username'),
    mysql_password          => hiera('etherpad_db_password'),
  }
}

# Node-OS: xenial
node /^etherpad-dev\d*\.open.*\.org$/ {
  $group = "etherpad-dev"
  class { 'openstack_project::server': }

  class { 'openstack_project::etherpad_dev':
    vhost_name     => 'etherpad-dev.openstack.org',
    mysql_host     => hiera('etherpad-dev_db_host', 'localhost'),
    mysql_user     => hiera('etherpad-dev_db_user', 'username'),
    mysql_password => hiera('etherpad-dev_db_password'),
  }
}

# Node-OS: trusty
node /^wiki\d+\.openstack\.org$/ {
  $group = "wiki"
  class { 'openstack_project::wiki':
    bup_user                  => 'bup-wiki',
    serveradmin               => hiera('infra_apache_serveradmin'),
    site_hostname             => 'wiki.openstack.org',
    ssl_cert_file_contents    => hiera('ssl_cert_file_contents'),
    ssl_key_file_contents     => hiera('ssl_key_file_contents'),
    ssl_chain_file_contents   => hiera('ssl_chain_file_contents'),
    wg_dbserver               => hiera('wg_dbserver'),
    wg_dbname                 => 'openstack_wiki',
    wg_dbuser                 => 'wikiuser',
    wg_dbpassword             => hiera('wg_dbpassword'),
    wg_secretkey              => hiera('wg_secretkey'),
    wg_upgradekey             => hiera('wg_upgradekey'),
    wg_recaptchasitekey       => hiera('wg_recaptchasitekey'),
    wg_recaptchasecretkey     => hiera('wg_recaptchasecretkey'),
    wg_googleanalyticsaccount => hiera('wg_googleanalyticsaccount'),
  }
}

# Node-OS: trusty
node /^wiki-dev\d+\.openstack\.org$/ {
  $group = "wiki-dev"
  class { 'openstack_project::wiki':
    serveradmin           => hiera('infra_apache_serveradmin'),
    site_hostname         => 'wiki-dev.openstack.org',
    wg_dbserver           => hiera('wg_dbserver'),
    wg_dbname             => 'openstack_wiki',
    wg_dbuser             => 'wikiuser',
    wg_dbpassword         => hiera('wg_dbpassword'),
    wg_secretkey          => hiera('wg_secretkey'),
    wg_upgradekey         => hiera('wg_upgradekey'),
    wg_recaptchasitekey   => hiera('wg_recaptchasitekey'),
    wg_recaptchasecretkey => hiera('wg_recaptchasecretkey'),
    disallow_robots       => true,
  }
}

# Node-OS: xenial
node /^logstash\d*\.open.*\.org$/ {
  class { 'openstack_project::server': }

  class { 'openstack_project::logstash':
    discover_nodes      => [
      'elasticsearch03.openstack.org:9200',
      'elasticsearch04.openstack.org:9200',
      'elasticsearch05.openstack.org:9200',
      'elasticsearch06.openstack.org:9200',
      'elasticsearch07.openstack.org:9200',
      'elasticsearch02.openstack.org:9200',
    ],
    subunit2sql_db_host => hiera('subunit2sql_db_host', ''),
    subunit2sql_db_pass => hiera('subunit2sql_db_password', ''),
  }
}

# Node-OS: xenial
node /^logstash-worker\d+\.open.*\.org$/ {
  $group = 'logstash-worker'

  class { 'openstack_project::server': }

  class { 'openstack_project::logstash_worker':
    discover_node         => 'elasticsearch03.openstack.org',
    enable_mqtt           => false,
    mqtt_password         => hiera('mqtt_service_user_password'),
    mqtt_ca_cert_contents => hiera('mosquitto_tls_ca_file'),
  }
}

# Node-OS: xenial
node /^subunit-worker\d+\.open.*\.org$/ {
  $group = "subunit-worker"
  class { 'openstack_project::server': }
  class { 'openstack_project::subunit_worker':
    subunit2sql_db_host   => hiera('subunit2sql_db_host', ''),
    subunit2sql_db_pass   => hiera('subunit2sql_db_password', ''),
    mqtt_pass             => hiera('mqtt_service_user_password'),
    mqtt_ca_cert_contents => hiera('mosquitto_tls_ca_file'),
  }
}

# Node-OS: xenial
node /^elasticsearch\d+\.open.*\.org$/ {
  $group = "elasticsearch"
  class { 'openstack_project::server': }
  class { 'openstack_project::elasticsearch_node':
    discover_nodes => $elasticsearch_nodes,
  }
}

# Node-OS: xenial
node /^firehose\d+\.open.*\.org$/ {
  class { 'openstack_project::server': }
  class { 'openstack_project::firehose':
    gerrit_ssh_host_key => hiera('gerrit_ssh_rsa_pubkey_contents'),
    gerrit_public_key   => hiera('germqtt_gerrit_ssh_public_key'),
    gerrit_private_key  => hiera('germqtt_gerrit_ssh_private_key'),
    mqtt_password       => hiera('mqtt_service_user_password'),
    ca_file             => hiera('mosquitto_tls_ca_file'),
    cert_file           => hiera('mosquitto_tls_server_cert_file'),
    key_file            => hiera('mosquitto_tls_server_key_file'),
    imap_hostname       => hiera('lpmqtt_imap_server'),
    imap_username       => hiera('lpmqtt_imap_username'),
    imap_password       => hiera('lpmqtt_imap_password'),
    statsd_host         => 'graphite.openstack.org',
  }
}

# CentOS machines to load balance git access.
# Node-OS: centos7
node /^git(-fe\d+)?\.open.*\.org$/ {
  $group = "git-loadbalancer"
  class { 'openstack_project::git':
    balancer_member_names   => [
      'git01.openstack.org',
      'git02.openstack.org',
      'git03.openstack.org',
      'git04.openstack.org',
      'git05.openstack.org',
      'git06.openstack.org',
      'git07.openstack.org',
      'git08.openstack.org',
    ],
    balancer_member_ips     => [
      '104.130.243.237',
      '104.130.243.109',
      '67.192.247.197',
      '67.192.247.180',
      '23.253.69.135',
      '104.239.132.223',
      '23.253.94.84',
      '104.239.146.131',
    ],
  }
}

# CentOS machines to run cgit and git daemon. Will be
# load balanced by git.openstack.org.
# Node-OS: centos7
node /^git\d+\.open.*\.org$/ {
  $group = "git-server"
  include openstack_project
  class { 'openstack_project::server': }

  class { 'openstack_project::git_backend':
    project_config_repo                     => 'https://git.openstack.org/openstack-infra/project-config',
    vhost_name                              => 'git.openstack.org',
    git_gerrit_ssh_key                      => hiera('gerrit_replication_ssh_rsa_pubkey_contents'),
    ssl_cert_file_contents                  => hiera('git_ssl_cert_file_contents'),
    ssl_key_file_contents                   => hiera('git_ssl_key_file_contents'),
    ssl_chain_file_contents                 => hiera('git_ssl_chain_file_contents'),
    git_zuul_ci_org_ssl_cert_file_contents  => hiera('git_zuul_ci_org_ssl_cert_file_contents'),
    git_zuul_ci_org_ssl_key_file_contents   => hiera('git_zuul_ci_org_ssl_key_file_contents'),
    git_zuul_ci_org_ssl_chain_file_contents => hiera('git_zuul_ci_org_ssl_chain_file_contents'),
    git_airshipit_org_ssl_cert_file_contents  => hiera('git_airshipit_org_ssl_cert_file_contents'),
    git_airshipit_org_ssl_key_file_contents   => hiera('git_airshipit_org_ssl_key_file_contents'),
    git_airshipit_org_ssl_chain_file_contents => hiera('git_airshipit_org_ssl_chain_file_contents'),
    git_starlingx_io_ssl_cert_file_contents  => hiera('git_starlingx_io_ssl_cert_file_contents'),
    git_starlingx_io_ssl_key_file_contents   => hiera('git_starlingx_io_ssl_key_file_contents'),
    git_starlingx_io_ssl_chain_file_contents => hiera('git_starlingx_io_ssl_chain_file_contents'),
    behind_proxy                            => true,
    selinux_mode                            => 'enforcing'
  }
}

# A machine to drive AFS mirror updates.
# Node-OS: xenial
node /^mirror-update\d*\.open.*\.org$/ {
  $group = "afsadmin"

  class { 'openstack_project::mirror_update':
    admin_keytab          => hiera('afsadmin_keytab'),
    fedora_keytab         => hiera('fedora_keytab'),
    opensuse_keytab       => hiera('opensuse_keytab'),
    reprepro_keytab       => hiera('reprepro_keytab'),
    gem_keytab            => hiera('gem_keytab'),
    centos_keytab         => hiera('centos_keytab'),
    epel_keytab           => hiera('epel_keytab'),
    yum_puppetlabs_keytab => hiera('yum_puppetlabs_keytab'),
  }
}

# Machines in each region to serve AFS mirrors.
# Node-OS: xenial
node /^mirror\d*\..*\.open.*\.org$/ {
  $group = "mirror"

  class { 'openstack_project::server':
    afs                       => true,
    afs_cache_size            => 50000000,  # 50GB
  }

  class { 'openstack_project::mirror':
    vhost_name => $::fqdn,
    require    => Class['Openstack_project::Server'],
  }
}

# Serve static AFS content for docs and other sites.
# Node-OS: xenial
node /^files\d*\.open.*\.org$/ {
  $group = "files"
  class { 'openstack_project::server':
    afs                       => true,
    afs_cache_size            => 10000000,  # 10GB
  }

  class { 'openstack_project::files':
    vhost_name                        => 'files.openstack.org',
    developer_cert_file_contents      => hiera('developer_cert_file_contents'),
    developer_key_file_contents       => hiera('developer_key_file_contents'),
    developer_chain_file_contents     => hiera('developer_chain_file_contents'),
    docs_cert_file_contents           => hiera('docs_cert_file_contents'),
    docs_key_file_contents            => hiera('docs_key_file_contents'),
    docs_chain_file_contents          => hiera('docs_chain_file_contents'),
    git_airship_cert_file_contents    => hiera('git_airship_cert_file_contents'),
    git_airship_key_file_contents     => hiera('git_airship_key_file_contents'),
    git_airship_chain_file_contents   => hiera('git_airship_chain_file_contents'),
    git_openstack_cert_file_contents  => hiera('git_openstack_cert_file_contents'),
    git_openstack_key_file_contents   => hiera('git_openstack_key_file_contents'),
    git_openstack_chain_file_contents => hiera('git_openstack_chain_file_contents'),
    git_starlingx_cert_file_contents  => hiera('git_starlingx_cert_file_contents'),
    git_starlingx_key_file_contents   => hiera('git_starlingx_key_file_contents'),
    git_starlingx_chain_file_contents => hiera('git_starlingx_chain_file_contents'),
    git_zuul_cert_file_contents       => hiera('git_zuul_cert_file_contents'),
    git_zuul_key_file_contents        => hiera('git_zuul_key_file_contents'),
    git_zuul_chain_file_contents      => hiera('git_zuul_chain_file_contents'),
    require                           => Class['Openstack_project::Server'],
  }

  # Temporary for evaluating htaccess rules
  ::httpd::vhost { "git-test.openstack.org":
    port          => 80, # Is required despite not being used.
    docroot       => "/afs/openstack.org/project/git-test/www",
    priority      => '50',
    template      => 'openstack_project/git-test.vhost.erb',
  }

  openstack_project::website { 'docs.starlingx.io':
    volume_name      => 'starlingx.io',
    aliases          => [],
    ssl_cert         => hiera('docs_starlingx_io_ssl_cert'),
    ssl_key          => hiera('docs_starlingx_io_ssl_key'),
    ssl_intermediate => hiera('docs_starlingx_io_ssl_intermediate'),
    require          => Class['openstack_project::files'],
  }

  openstack_project::website { 'docs.opendev.org':
    aliases          => [],
    docroot	     => "/afs/openstack.org/project/opendev.org/docs",
    ssl_cert         => hiera('docs_opendev_ssl_cert'),
    ssl_key          => hiera('docs_opendev_ssl_key'),
    ssl_intermediate => hiera('docs_opendev_ssl_intermediate'),
    require          => Class['openstack_project::files'],
  }

  openstack_project::website { 'zuul-ci.org':
    aliases          => ['www.zuul-ci.org', 'zuulci.org', 'www.zuulci.org'],
    ssl_cert         => hiera('zuul-ci_org_ssl_cert'),
    ssl_key          => hiera('zuul-ci_org_ssl_key'),
    ssl_intermediate => hiera('zuul-ci_org_ssl_intermediate'),
    require          => Class['openstack_project::files'],
  }

}

# Node-OS: trusty
# Node-OS: xenial
node /^refstack\d*\.open.*\.org$/ {
  class { 'openstack_project::server': }
  class { 'refstack':
    mysql_host          => hiera('refstack_mysql_host', 'localhost'),
    mysql_database      => hiera('refstack_mysql_db_name', 'refstack'),
    mysql_user          => hiera('refstack_mysql_user', 'refstack'),
    mysql_user_password => hiera('refstack_mysql_password'),
    ssl_cert_content    => hiera('refstack_ssl_cert_file_contents'),
    ssl_cert            => '/etc/ssl/certs/refstack.pem',
    ssl_key_content     => hiera('refstack_ssl_key_file_contents'),
    ssl_key             => '/etc/ssl/private/refstack.key',
    ssl_ca_content      => hiera('refstack_ssl_chain_file_contents'),
    ssl_ca              => '/etc/ssl/certs/refstack.ca.pem',
    protocol            => 'https',
  }
  mysql_backup::backup_remote { 'refstack':
    database_host     => hiera('refstack_mysql_host', 'localhost'),
    database_user     => hiera('refstack_mysql_user', 'refstack'),
    database_password => hiera('refstack_mysql_password'),
    require           => Class['::refstack'],
  }
}

# A machine to run Storyboard
# Node-OS: xenial
node /^storyboard\d+\.opendev\.org$/ {
  $group = "storyboard"
  class { 'openstack_project::storyboard':
    project_config_repo     => 'https://git.openstack.org/openstack-infra/project-config',
    mysql_host              => hiera('storyboard_db_host', 'localhost'),
    mysql_user              => hiera('storyboard_db_user', 'username'),
    mysql_password          => hiera('storyboard_db_password'),
    rabbitmq_user           => hiera('storyboard_rabbit_user', 'username'),
    rabbitmq_password       => hiera('storyboard_rabbit_password'),
    ssl_cert                => '/etc/ssl/certs/storyboard.openstack.org.pem',
    ssl_cert_file_contents  => hiera('storyboard_ssl_cert_file_contents'),
    ssl_key                 => '/etc/ssl/private/storyboard.openstack.org.key',
    ssl_key_file_contents   => hiera('storyboard_ssl_key_file_contents'),
    ssl_chain_file_contents => hiera('storyboard_ssl_chain_file_contents'),
    hostname                => 'storyboard.openstack.org',
    valid_oauth_clients     => [
      'storyboard.openstack.org',
      'logs.openstack.org',
    ],
    cors_allowed_origins     => [
      'https://storyboard.openstack.org',
      'http://logs.openstack.org',
    ],
    sender_email_address => 'storyboard@storyboard.openstack.org',
    default_url          => 'https://storyboard.openstack.org',
  }
}

# A machine to run Storyboard devel
# Node-OS: xenial
node /^storyboard-dev\d+\.opendev\.org$/ {
  $group = "storyboard-dev"
  class { 'openstack_project::storyboard::dev':
    project_config_repo     => 'https://git.openstack.org/openstack-infra/project-config',
    mysql_host              => hiera('storyboard_db_host', 'localhost'),
    mysql_user              => hiera('storyboard_db_user', 'username'),
    mysql_password          => hiera('storyboard_db_password'),
    rabbitmq_user           => hiera('storyboard_rabbit_user', 'username'),
    rabbitmq_password       => hiera('storyboard_rabbit_password'),
    hostname                => 'storyboard-dev.openstack.org',
    valid_oauth_clients     => [
      'storyboard-dev.openstack.org',
      'logs.openstack.org',
    ],
    cors_allowed_origins     => [
      'https://storyboard-dev.openstack.org',
      'http://logs.openstack.org',
    ],
    sender_email_address => 'storyboard-dev@storyboard-dev.openstack.org',
    default_url          => 'https://storyboard-dev.openstack.org',
  }

}

# A machine to serve static content.
# Node-OS: trusty
# Node-OS: xenial
node /^static\d*\.open.*\.org$/ {
  class { 'openstack_project::server': }
  class { 'openstack_project::static':
    project_config_repo     => 'https://git.openstack.org/openstack-infra/project-config',
    swift_authurl           => 'https://identity.api.rackspacecloud.com/v2.0/',
    swift_user              => 'infra-files-ro',
    swift_key               => hiera('infra_files_ro_password'),
    swift_tenant_name       => hiera('infra_files_tenant_name', 'tenantname'),
    swift_region_name       => 'DFW',
    swift_default_container => 'infra-files',
    ssl_cert_file_contents  => hiera('static_ssl_cert_file_contents'),
    ssl_key_file_contents   => hiera('static_ssl_key_file_contents'),
    ssl_chain_file_contents => hiera('static_ssl_chain_file_contents'),
  }
}

# Node-OS: xenial
node /^zk\d+\.open.*\.org$/ {
  # We use IP addresses here so that zk listens on the public facing addresses
  # allowing cluster members to talk to each other. Without this they listen
  # on 127.0.1.1 because that is what we have in /etc/hosts for
  # zk0X.openstack.org.
  $zk_cluster_members = [
    '23.253.236.126', # zk01
    '172.99.117.32',  # zk02
    '23.253.90.246',  # zk03
  ]
  class { 'openstack_project::server': }

  class { '::zookeeper':
    # ID needs to be numeric, so we use regex to extra numbers from fqdn.
    id             => regsubst($::fqdn, '^zk(\d+)\.open.*\.org$', '\1'),
    # The frequency in hours to look for and purge old snapshots,
    # defaults to 0 (disabled). The number of retained snapshots can
    # be separately controlled through snap_retain_count and
    # defaults to the minimum value of 3. This will quickly fill the
    # disk in production if not enabled. Works on ZK >=3.4.
    purge_interval => 6,
    servers        => $zk_cluster_members,
  }
}

# A machine to serve various project status updates.
# Node-OS: trusty
# Node-OS: xenial
node /^status\d*\.open.*\.org$/ {
  $group = 'status'

  class { 'openstack_project::server': }

  class { 'openstack_project::status':
    gerrit_host                   => 'review.openstack.org',
    gerrit_ssh_host_key           => hiera('gerrit_ssh_rsa_pubkey_contents'),
    reviewday_ssh_public_key      => hiera('reviewday_rsa_pubkey_contents'),
    reviewday_ssh_private_key     => hiera('reviewday_rsa_key_contents'),
    recheck_ssh_public_key        => hiera('elastic-recheck_gerrit_ssh_public_key'),
    recheck_ssh_private_key       => hiera('elastic-recheck_gerrit_ssh_private_key'),
    recheck_bot_nick              => 'openstackrecheck',
    recheck_bot_passwd            => hiera('elastic-recheck_ircbot_password'),
  }
}

# Node-OS: xenial
node /^survey\d+\.open.*\.org$/ {
  $group = "survey"
  class { 'openstack_project::server': }

  class { 'openstack_project::survey':
    vhost_name              => 'survey.openstack.org',
    auth_openid             => true,
    ssl_cert_file_contents  => hiera('ssl_cert_file_contents'),
    ssl_key_file_contents   => hiera('ssl_key_file_contents'),
    ssl_chain_file_contents => hiera('ssl_chain_file_contents'),
    dbpassword              => hiera('dbpassword'),
    dbhost                  => hiera('dbhost'),
    adminuser               => hiera('adminuser'),
    adminpass               => hiera('adminpass'),
    adminmail               => hiera('adminmail'),
  }
}

# Node-OS: xenial
node /^nl\d+\.open.*\.org$/ {
  $group = 'nodepool'

  # NOTE(ianw) From 09-2018 (https://review.openstack.org/#/c/598329/)
  # the cloud credentials are deployed with ansible via the
  # configure-openstacksdk role and are no longer configured here

  class { 'openstack_project::server': }

  include openstack_project

  class { '::openstackci::nodepool_launcher':
    nodepool_ssh_private_key => hiera('zuul_worker_ssh_private_key_contents'),
    project_config_repo      => 'https://git.openstack.org/openstack-infra/project-config',
    statsd_host              => 'graphite.openstack.org',
    revision                 => 'master',
    python_version           => 3,
    enable_webapp            => true,
  }
}

# Node-OS: xenial
node /^nb\d+\.open.*\.org$/ {
  $group = 'nodepool'

  class { 'openstack_project::server': }

  include openstack_project

  class { '::openstackci::nodepool_builder':
    nodepool_ssh_public_key       => hiera('zuul_worker_ssh_public_key_contents'),
    vhost_name                    => $::fqdn,
    enable_build_log_via_http     => true,
    project_config_repo           => 'https://git.openstack.org/openstack-infra/project-config',
    statsd_host                   => 'graphite.openstack.org',
    upload_workers                => '16',
    revision                      => 'master',
    python_version                => 3,
    zuulv3                        => true,
    ssl_cert_file                 => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
    ssl_key_file                  => '/etc/ssl/private/ssl-cert-snakeoil.key',
  }

  cron { 'mirror_gitgc':
    user        => 'nodepool',
    hour        => '20',
    minute      => '0',
    command     => 'find /opt/dib_cache/source-repositories/ -type d -name "*.git" -exec git --git-dir="{}" gc \; >/dev/null',
    environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
    require     => Class['::openstackci::nodepool_builder'],
  }
}

# Node-OS: xenial
node /^ze\d+\.open.*\.org$/ {
  $group = "zuul-executor"

  $gerrit_server           = 'review.openstack.org'
  $gerrit_user             = 'zuul'
  $gerrit_ssh_host_key     = hiera('gerrit_ssh_rsa_pubkey_contents')
  $gerrit_ssh_private_key  = hiera('gerrit_ssh_private_key_contents')
  $zuul_ssh_private_key    = hiera('zuul_ssh_private_key_contents')
  $zuul_static_private_key = hiera('jenkins_ssh_private_key_contents')
  $git_email               = 'zuul@openstack.org'
  $git_name                = 'OpenStack Zuul'
  $revision                = 'master'

  class { 'openstack_project::server':
    afs                       => true,
  }

  class { '::project_config':
    url => 'https://git.openstack.org/openstack-infra/project-config',
  }

  # We use later HWE kernels for better memory managment, requiring an
  # updated AFS version which we install from our custom ppa.
  include ::apt
  apt::ppa { 'ppa:openstack-ci-core/openafs-amd64-hwe': }
  package { 'linux-generic-hwe-16.04':
    ensure  => present,
    require => [
      Apt::Ppa['ppa:openstack-ci-core/openafs-amd64-hwe'],
      Class['apt::update'],
    ],
  }

  # Skopeo is required for pushing/pulling from the intermediate
  # registry, and is available in the projectatomic ppa.

  apt::ppa { 'ppa:projectatomic/ppa': }
  package { 'skopeo':
    ensure  => present,
    require => [
      Apt::Ppa['ppa:projectatomic/ppa'],
      Class['apt::update'],
    ],
  }

  # NOTE(pabelanger): We call ::zuul directly, so we can override all in one
  # settings.
  class { '::zuul':
    gearman_server           => 'zuul01.openstack.org',
    gerrit_server            => $gerrit_server,
    gerrit_user              => $gerrit_user,
    zuul_ssh_private_key     => $gerrit_ssh_private_key,
    git_email                => $git_email,
    git_name                 => $git_name,
    worker_private_key_file  => '/var/lib/zuul/ssh/nodepool_id_rsa',
    revision                 => $revision,
    python_version           => 3,
    zookeeper_hosts          => 'zk01.openstack.org:2181,zk02.openstack.org:2181,zk03.openstack.org:2181',
    zuulv3                   => true,
    connections              => hiera('zuul_connections', []),
    gearman_client_ssl_cert  => hiera('gearman_client_ssl_cert'),
    gearman_client_ssl_key   => hiera('gearman_client_ssl_key'),
    gearman_ssl_ca           => hiera('gearman_ssl_ca'),
    #TODO(pabelanger): Add openafs role for zuul-jobs to setup /etc/openafs
    # properly. We need to revisting this post Queens PTG.
    trusted_ro_paths         => ['/etc/openafs', '/etc/ssl/certs', '/var/lib/zuul/ssh'],
    trusted_rw_paths         => ['/afs'],
    untrusted_ro_paths       => ['/etc/ssl/certs'],
    disk_limit_per_job       => 5000,  # Megabytes
    site_variables_yaml_file => $::project_config::zuul_site_variables_yaml,
    require                  => $::project_config::config_dir,
    statsd_host              => 'graphite.openstack.org',
  }

  class { '::zuul::executor': }

  # This is used by the log job submission playbook which runs under
  # python2
  package { 'gear':
    ensure   => latest,
    provider => openstack_pip,
    require  => Class['pip'],
  }

  file { '/var/lib/zuul/ssh/nodepool_id_rsa':
    owner   => 'zuul',
    group   => 'zuul',
    mode    => '0400',
    require => File['/var/lib/zuul/ssh'],
    content => $zuul_ssh_private_key,
  }

  file { '/var/lib/zuul/ssh/static_id_rsa':
    owner   => 'zuul',
    group   => 'zuul',
    mode    => '0400',
    require => File['/var/lib/zuul/ssh'],
    content => $zuul_static_private_key,
  }

  class { '::zuul::known_hosts':
    known_hosts_content => "[review.openstack.org]:29418,[104.130.246.32]:29418,[2001:4800:7819:103:be76:4eff:fe04:9229]:29418 ${gerrit_ssh_host_key}\n[git.opendaylight.org]:29418,[52.35.122.251]:29418,[2600:1f14:421:f500:7b21:2a58:ab0a:2d17]:29418 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAyRXyHEw/P1iZr/fFFzbodT5orVV/ftnNRW59Zh9rnSY5Rmbc9aygsZHdtiWBERVVv8atrJSdZool75AglPDDYtPICUGWLR91YBSDcZwReh5S9es1dlQ6fyWTnv9QggSZ98KTQEuE3t/b5SfH0T6tXWmrNydv4J2/mejKRRLU2+oumbeVN1yB+8Uau/3w9/K5F5LgsDDzLkW35djLhPV8r0OfmxV/cAnLl7AaZlaqcJMA+2rGKqM3m3Yu+pQw4pxOfCSpejlAwL6c8tA9naOvBkuJk+hYpg5tDEq2QFGRX5y1F9xQpwpdzZROc5hdGYntM79VMMXTj+95dwVv/8yTsw==\n",
  }
}

# Node-OS: xenial
node /^zuul\d+\.open.*\.org$/ {
  $group = "zuul-scheduler"
  $gerrit_server        = 'review.openstack.org'
  $gerrit_user          = 'zuul'
  $gerrit_ssh_host_key  = hiera('gerrit_zuul_user_ssh_key_contents')
  $zuul_ssh_private_key = hiera('zuul_ssh_private_key_contents')
  $zuul_url             = "http://zuul.openstack.org/p"
  $git_email            = 'zuul@openstack.org'
  $git_name             = 'OpenStack Zuul'
  $revision             = 'master'

  class { 'openstack_project::server': }

  class { '::project_config':
    url => 'https://git.openstack.org/openstack-infra/project-config',
  }

  # NOTE(pabelanger): We call ::zuul directly, so we can override all in one
  # settings.
  class { '::zuul':
    gerrit_server                 => $gerrit_server,
    gerrit_user                   => $gerrit_user,
    zuul_ssh_private_key          => $zuul_ssh_private_key,
    git_email                     => $git_email,
    git_name                      => $git_name,
    revision                      => $revision,
    python_version                => 3,
    zookeeper_hosts               => 'zk01.openstack.org:2181,zk02.openstack.org:2181,zk03.openstack.org:2181',
    zookeeper_session_timeout     => 40,
    zuulv3                        => true,
    connections                   => hiera('zuul_connections', []),
    connection_secrets            => hiera('zuul_connection_secrets', []),
    vhost_name                    => 'zuul.openstack.org',
    zuul_status_url               => 'http://127.0.0.1:8001/openstack',
    zuul_web_url                  => 'http://127.0.0.1:9000',
    zuul_tenant_name              => 'openstack',
    gearman_client_ssl_cert       => hiera('gearman_client_ssl_cert'),
    gearman_client_ssl_key        => hiera('gearman_client_ssl_key'),
    gearman_server_ssl_cert       => hiera('gearman_server_ssl_cert'),
    gearman_server_ssl_key        => hiera('gearman_server_ssl_key'),
    gearman_ssl_ca                => hiera('gearman_ssl_ca'),
    proxy_ssl_cert_file_contents  => hiera('zuul_ssl_cert_file_contents'),
    proxy_ssl_chain_file_contents => hiera('zuul_ssl_chain_file_contents'),
    proxy_ssl_key_file_contents   => hiera('zuul_ssl_key_file_contents'),
    statsd_host                   => 'graphite.openstack.org',
    status_url                    => 'https://zuul.openstack.org',
    relative_priority             => true,
  }

  file { "/etc/zuul/github.key":
    ensure  => present,
    owner   => 'zuul',
    group   => 'zuul',
    mode    => '0600',
    content => hiera('zuul_github_app_key'),
    require => File['/etc/zuul'],
  }

  class { '::zuul::scheduler':
    layout_dir     => $::project_config::zuul_layout_dir,
    require        => $::project_config::config_dir,
    python_version => 3,
    use_mysql      => true,
  }

  class { '::zuul::web':
    # We manage backups below
    enable_status_backups => false,
    vhosts => {
      'zuul.openstack.org' => {
        port       => 443,
        docroot    => '/opt/zuul-web/content',
        priority   => '50',
        ssl        => true,
        template   => 'zuul/zuulv3.vhost.erb',
        vhost_name => 'zuul.openstack.org',
      },
      'zuul.opendev.org' => {
        port       => 443,
        docroot    => '/opt/zuul-web/content',
        priority   => '40',
        ssl        => true,
        template   => 'zuul/zuulv3.vhost.erb',
        vhost_name => 'zuul.opendev.org',
      },
      'zuul.openstack.org-http' => {
        port       => 80,
        docroot    => '/opt/zuul-web/content',
        priority   => '50',
        ssl        => false,
        template   => 'zuul/zuulv3.vhost.erb',
        vhost_name => 'zuul.openstack.org',
      },
      'zuul.opendev.org-http' => {
        port       => 80,
        docroot    => '/opt/zuul-web/content',
        priority   => '40',
        ssl        => false,
        template   => 'zuul/zuulv3.vhost.erb',
        vhost_name => 'zuul.opendev.org',
      },
    },
    vhosts_flags => {
      'zuul.openstack.org' => {
        tenant_name => 'openstack',
        ssl         => true,
      },
      'zuul.opendev.org' => {
        tenant_name => '',
        ssl         => true,
      },
      'zuul.openstack.org-http' => {
        tenant_name => 'openstack',
        ssl         => false,
      },
      'zuul.opendev.org-http' => {
        tenant_name => '',
        ssl         => false,
      },
    },
    vhosts_ssl => {
      'zuul.openstack.org' => {
        ssl_cert_file_contents  => hiera('zuul_ssl_cert_file_contents'),
        ssl_chain_file_contents => hiera('zuul_ssl_chain_file_contents'),
        ssl_key_file_contents   => hiera('zuul_ssl_key_file_contents'),
      },
      'zuul.opendev.org' => {
        ssl_cert_file_contents  => hiera('opendev_zuul_ssl_cert_file_contents'),
        ssl_chain_file_contents => hiera('opendev_zuul_ssl_chain_file_contents'),
        ssl_key_file_contents   => hiera('opendev_zuul_ssl_key_file_contents'),
      },
    },
  }

  zuul::status_backups { 'openstack-zuul-tenant':
    tenant_name => 'openstack',
    ssl         => true,
    status_uri  => 'https://zuul.opendev.org/api/tenant/openstack/status',
  }

  zuul::status_backups { 'kata-zuul-tenant':
    tenant_name => 'kata-containers',
    ssl         => true,
    status_uri  => 'https://zuul.opendev.org/api/tenant/kata-containers/status',
  }

  class { '::zuul::fingergw': }

  class { '::zuul::known_hosts':
    known_hosts_content => "[review.openstack.org]:29418,[104.130.246.32]:29418,[2001:4800:7819:103:be76:4eff:fe04:9229]:29418 ${gerrit_ssh_host_key}\n[git.opendaylight.org]:29418,[52.35.122.251]:29418,[2600:1f14:421:f500:7b21:2a58:ab0a:2d17]:29418 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAyRXyHEw/P1iZr/fFFzbodT5orVV/ftnNRW59Zh9rnSY5Rmbc9aygsZHdtiWBERVVv8atrJSdZool75AglPDDYtPICUGWLR91YBSDcZwReh5S9es1dlQ6fyWTnv9QggSZ98KTQEuE3t/b5SfH0T6tXWmrNydv4J2/mejKRRLU2+oumbeVN1yB+8Uau/3w9/K5F5LgsDDzLkW35djLhPV8r0OfmxV/cAnLl7AaZlaqcJMA+2rGKqM3m3Yu+pQw4pxOfCSpejlAwL6c8tA9naOvBkuJk+hYpg5tDEq2QFGRX5y1F9xQpwpdzZROc5hdGYntM79VMMXTj+95dwVv/8yTsw==\n",
  }

  include bup
  bup::site { 'rax.ord':
    backup_user   => 'bup-zuulv3',
    backup_server => 'backup01.ord.rax.ci.openstack.org',
  }

}

# Node-OS: xenial
node /^zm\d+.open.*\.org$/ {
  $group = "zuul-merger"

  $gerrit_server        = 'review.openstack.org'
  $gerrit_user          = 'zuul'
  $gerrit_ssh_host_key  = hiera('gerrit_ssh_rsa_pubkey_contents')
  $zuul_ssh_private_key = hiera('zuulv3_ssh_private_key_contents')
  $zuul_url             = "http://${::fqdn}/p"
  $git_email            = 'zuul@openstack.org'
  $git_name             = 'OpenStack Zuul'
  $revision             = 'master'

  class { 'openstack_project::server': }

  # NOTE(pabelanger): We call ::zuul directly, so we can override all in one
  # settings.
  class { '::zuul':
    gearman_server          => 'zuul01.openstack.org',
    gerrit_server           => $gerrit_server,
    gerrit_user             => $gerrit_user,
    zuul_ssh_private_key    => $zuul_ssh_private_key,
    git_email               => $git_email,
    git_name                => $git_name,
    revision                => $revision,
    python_version          => 3,
    zookeeper_hosts         => 'zk01.openstack.org:2181,zk02.openstack.org:2181,zk03.openstack.org:2181',
    zuulv3                  => true,
    connections             => hiera('zuul_connections', []),
    gearman_client_ssl_cert => hiera('gearman_client_ssl_cert'),
    gearman_client_ssl_key  => hiera('gearman_client_ssl_key'),
    gearman_ssl_ca          => hiera('gearman_ssl_ca'),
    statsd_host             => 'graphite.openstack.org',
  }

  class { 'openstack_project::zuul_merger':
    gerrit_server        => $gerrit_server,
    gerrit_user          => $gerrit_user,
    gerrit_ssh_host_key  => $gerrit_ssh_host_key,
    zuul_ssh_private_key => $zuul_ssh_private_key,
    manage_common_zuul   => false,
  }
}

# Node-OS: xenial
node /^pbx\d*\.open.*\.org$/ {
  $group = "pbx"
  class { 'openstack_project::server': }
  class { 'openstack_project::pbx':
    sip_providers => [
      {
        provider => 'voipms',
        hostname => 'dallas.voip.ms',
        username => hiera('voipms_username', 'username'),
        password => hiera('voipms_password'),
        outgoing => false,
      },
    ],
  }
}

# Node-OS: xenial
# A backup machine.  Don't run cron or puppet agent on it.
node /^backup\d+\..*\.ci\.open.*\.org$/ {
  $group = "ci-backup"
  class { 'openstack_project::server': }
  include openstack_project::backup_server
}

# Node-OS: xenial
node /^openstackid\d*(\.openstack)?\.org$/ {
  $group = "openstackid"
  class { 'openstack_project::openstackid_prod':
    site_admin_password                 => hiera('openstackid_site_admin_password'),
    id_mysql_host                       => hiera('openstackid_id_mysql_host', 'localhost'),
    id_mysql_password                   => hiera('openstackid_id_mysql_password'),
    id_mysql_user                       => hiera('openstackid_id_mysql_user', 'username'),
    id_db_name                          => hiera('openstackid_id_db_name'),
    ss_mysql_host                       => hiera('openstackid_ss_mysql_host', 'localhost'),
    ss_mysql_password                   => hiera('openstackid_ss_mysql_password'),
    ss_mysql_user                       => hiera('openstackid_ss_mysql_user', 'username'),
    ss_db_name                          => hiera('openstackid_ss_db_name', 'username'),
    redis_password                      => hiera('openstackid_redis_password'),
    ssl_cert_file_contents              => hiera('openstackid_ssl_cert_file_contents'),
    ssl_key_file_contents               => hiera('openstackid_ssl_key_file_contents'),
    ssl_chain_file_contents             => hiera('openstackid_ssl_chain_file_contents'),
    id_recaptcha_public_key             => hiera('openstackid_recaptcha_public_key'),
    id_recaptcha_private_key            => hiera('openstackid_recaptcha_private_key'),
    vhost_name                          => 'openstackid.org',
    session_cookie_domain               => 'openstackid.org',
    serveradmin                         => 'webmaster@openstackid.org',
    canonicalweburl                     => 'https://openstackid.org/',
    app_url                             => 'https://openstackid.org',
    app_key                             => hiera('openstackid_app_key'),
    id_log_error_to_email               => 'openstack@tipit.net',
    id_log_error_from_email             => 'noreply@openstack.org',
    email_driver                        => 'smtp',
    email_smtp_server                   => 'smtp.sendgrid.net',
    email_smtp_server_user              => hiera('openstackid_smtp_user'),
    email_smtp_server_password          => hiera('openstackid_smtp_password'),
    php_version                         => 7,
    mysql_ssl_enabled                   => true,
    mysql_ssl_ca_file_contents          => hiera('openstackid_mysql_ssl_ca_file_contents'),
    mysql_ssl_client_key_file_contents  => hiera('openstackid_mysql_ssl_client_key_file_contents'),
    mysql_ssl_client_cert_file_contents => hiera('openstackid_mysql_ssl_client_cert_file_contents'),
  }
}

# Node-OS: xenial
node /^openstackid-dev\d*\.openstack\.org$/ {
  $group = "openstackid-dev"
  class { 'openstack_project::openstackid_dev':
    site_admin_password                 => hiera('openstackid_dev_site_admin_password'),
    id_mysql_host                       => hiera('openstackid_dev_id_mysql_host', 'localhost'),
    id_mysql_password                   => hiera('openstackid_dev_id_mysql_password'),
    id_mysql_user                       => hiera('openstackid_dev_id_mysql_user', 'username'),
    ss_mysql_host                       => hiera('openstackid_dev_ss_mysql_host', 'localhost'),
    ss_mysql_password                   => hiera('openstackid_dev_ss_mysql_password'),
    ss_mysql_user                       => hiera('openstackid_dev_ss_mysql_user', 'username'),
    ss_db_name                          => hiera('openstackid_dev_ss_db_name', 'username'),
    redis_password                      => hiera('openstackid_dev_redis_password'),
    ssl_cert_file_contents              => hiera('openstackid_dev_ssl_cert_file_contents'),
    ssl_key_file_contents               => hiera('openstackid_dev_ssl_key_file_contents'),
    ssl_chain_file_contents             => hiera('openstackid_dev_ssl_chain_file_contents'),
    id_recaptcha_public_key             => hiera('openstackid_dev_recaptcha_public_key'),
    id_recaptcha_private_key            => hiera('openstackid_dev_recaptcha_private_key'),
    vhost_name                          => 'openstackid-dev.openstack.org',
    session_cookie_domain               => 'openstackid-dev.openstack.org',
    serveradmin                         => 'webmaster@openstackid-dev.openstack.org',
    canonicalweburl                     => 'https://openstackid-dev.openstack.org/',
    app_url                             => 'https://openstackid-dev.openstack.org',
    app_key                             => hiera('openstackid_dev_app_key'),
    id_log_error_to_email               => 'openstack@tipit.net',
    id_log_error_from_email             => 'noreply@openstack.org',
    email_driver                        => 'sendgrid',
    email_send_grid_api_key             => hiera('openstackid_dev_send_grid_api_key'),
    php_version                         => 7,
    mysql_ssl_enabled                   => true,
    mysql_ssl_ca_file_contents          => hiera('openstackid_dev_mysql_ssl_ca_file_contents'),
    mysql_ssl_client_key_file_contents  => hiera('openstackid_dev_mysql_ssl_client_key_file_contents'),
    mysql_ssl_client_cert_file_contents => hiera('openstackid_dev_mysql_ssl_client_cert_file_contents'),
  }
}

# Node-OS: trusty
# Used for testing all-in-one deployments
node 'single-node-ci.test.only' {
  include ::openstackci::single_node_ci
}

# Node-OS: xenial
node /^kdc03\.open.*\.org$/ {
  class { 'openstack_project::server': }

  class { 'openstack_project::kdc': }
}

# Node-OS: xenial
node /^kdc04\.open.*\.org$/ {
  class { 'openstack_project::server': }

  class { 'openstack_project::kdc':
    slave => true,
  }
}

# Node-OS: xenial
node /^afsdb01\.open.*\.org$/ {
  $group = "afsdb"

  class { 'openstack_project::server':
    afs                       => true,
  }

  include openstack_project::afsdb
  include openstack_project::afsrelease
}

# Node-OS: xenial
node /^afsdb.*\.open.*\.org$/ {
  $group = "afsdb"

  class { 'openstack_project::server':
    afs                       => true,
  }

  include openstack_project::afsdb
}

# Node-OS: xenial
node /^afs.*\..*\.open.*\.org$/ {
  $group = "afs"

  class { 'openstack_project::server':
    afs                       => true,
  }

  include openstack_project::afsfs
}

# Node-OS: trusty
node /^ask\d*\.open.*\.org$/ {

  class { 'openstack_project::server': }

  class { 'openstack_project::ask':
    db_user                      => hiera('ask_db_user', 'ask'),
    db_password                  => hiera('ask_db_password'),
    redis_password               => hiera('ask_redis_password'),
    site_ssl_cert_file_contents  => hiera('ask_site_ssl_cert_file_contents', undef),
    site_ssl_key_file_contents   => hiera('ask_site_ssl_key_file_contents', undef),
    site_ssl_chain_file_contents => hiera('ask_site_ssl_chain_file_contents', undef),
  }
}

# Node-OS: trusty
node /^ask-staging\d*\.open.*\.org$/ {
  class { 'openstack_project::server': }

  class { 'openstack_project::ask_staging':
    db_password                  => hiera('ask_staging_db_password'),
    redis_password               => hiera('ask_staging_redis_password'),
  }
}

# Node-OS: xenial
node /^translate\d+\.open.*\.org$/ {
  $group = "translate"
  class { 'openstack_project::server': }
  class { 'openstack_project::translate':
    admin_users                => 'aeng,cboylan,eumel8,ianw,ianychoi,infra,jaegerandi,mordred,stevenk',
    openid_url                 => 'https://openstackid.org',
    listeners                  => ['ajp'],
    from_address               => 'noreply@openstack.org',
    mysql_host                 => hiera('translate_mysql_host', 'localhost'),
    mysql_password             => hiera('translate_mysql_password'),
    zanata_server_user         => hiera('proposal_zanata_user'),
    zanata_server_api_key      => hiera('proposal_zanata_api_key'),
    zanata_wildfly_version     => '10.1.0',
    zanata_wildfly_install_url => 'https://repo1.maven.org/maven2/org/wildfly/wildfly-dist/10.1.0.Final/wildfly-dist-10.1.0.Final.tar.gz',
    zanata_main_version        => 4,
    zanata_url                 => 'https://github.com/zanata/zanata-platform/releases/download/platform-4.3.3/zanata-4.3.3-wildfly.zip',
    zanata_checksum            => 'eaf8bd07401dade758b677007d2358f173193d17',
    project_config_repo        => 'https://git.openstack.org/openstack-infra/project-config',
    ssl_cert_file_contents     => hiera('translate_ssl_cert_file_contents'),
    ssl_key_file_contents      => hiera('translate_ssl_key_file_contents'),
    ssl_chain_file_contents    => hiera('translate_ssl_chain_file_contents'),
    vhost_name                 => 'translate.openstack.org',
  }
}

# Node-OS: xenial
node /^translate-dev\d*\.open.*\.org$/ {
  $group = "translate-dev"
  class { 'openstack_project::translate_dev':
    admin_users           => 'aeng,cboylan,eumel,eumel8,ianw,ianychoi,infra,jaegerandi,mordred,stevenk',
    openid_url            => 'https://openstackid-dev.openstack.org',
    listeners             => ['ajp'],
    from_address          => 'noreply@openstack.org',
    mysql_host            => hiera('translate_dev_mysql_host', 'localhost'),
    mysql_password        => hiera('translate_dev_mysql_password'),
    zanata_server_user    => hiera('proposal_zanata_user'),
    zanata_server_api_key => hiera('proposal_zanata_api_key'),
    project_config_repo   => 'https://git.openstack.org/openstack-infra/project-config',
    vhost_name            => 'translate-dev.openstack.org',
  }
}


# Node-OS: xenial
node /^codesearch\d*\.open.*\.org$/ {
  $group = "codesearch"
  class { 'openstack_project::server': }
  class { 'openstack_project::codesearch':
    project_config_repo => 'https://git.openstack.org/openstack-infra/project-config',
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
