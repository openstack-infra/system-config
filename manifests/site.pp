#
# Top-level variables
#
# There must not be any whitespace between this comment and the variables or
# in between any two variables in order for them to be correctly parsed and
# passed around in test.sh
#
$elasticsearch_nodes = hiera_array('elasticsearch_nodes')

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
node 'review.openstack.org' {
  $iptables_rules =
    ['-p tcp --syn --dport 29418 -m connlimit --connlimit-above 100 -j REJECT']
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443, 29418],
    iptables_rules6           => $iptables_rules,
    iptables_rules4           => $iptables_rules,
    extra_aliases             => { 'gerrit2' => 'root' },
  }

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
node 'review01.openstack.org' {
  $group = "review"

  $iptables_rules =
    ['-p tcp --syn --dport 29418 -m connlimit --connlimit-above 100 -j REJECT']
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443, 29418],
    iptables_rules6           => $iptables_rules,
    iptables_rules4           => $iptables_rules,
    extra_aliases             => { 'gerrit2' => 'root' },
  }

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
node /^review-dev\d*\.openstack\.org$/ {
  $group = "review-dev"

  $iptables_rules =
    ['-p tcp --syn --dport 29418 -m connlimit --connlimit-above 100 -j REJECT']
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443, 29418],
    iptables_rules6           => $iptables_rules,
    iptables_rules4           => $iptables_rules,
    extra_aliases             => { 'gerrit2' => 'root' },
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
node /^grafana\d*\.openstack\.org$/ {
  $group = "grafana"
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
  }
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

# Node-OS: trusty
# Node-OS: xenial
node /^health\d*\.openstack\.org$/ {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
  }
  class { 'openstack_project::openstack_health_api':
    subunit2sql_db_host => hiera('subunit2sql_db_host', 'localhost'),
  }
}

# Node-OS: xenial
node /^cacti\d+\.openstack\.org$/ {
  $group = "cacti"
  include openstack_project::ssl_cert_check
  class { 'openstack_project::cacti':
    cacti_hosts => hiera_array('cacti_hosts'),
    vhost_name  => 'cacti.openstack.org',
  }
}

# Node-OS: trusty
node 'puppetmaster.openstack.org' {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [8140],
    pin_puppet                => '3.6.',
  }
  class { 'openstack_project::puppetmaster':
    root_rsa_key                               => hiera('puppetmaster_root_rsa_key'),
    puppetmaster_clouds                        => hiera('puppetmaster_clouds'),
    enable_mqtt                                => true,
    mqtt_password                              => hiera('mqtt_service_user_password'),
    mqtt_ca_cert_contents                      => hiera('mosquitto_tls_ca_file'),
  }
  file { '/etc/openstack/limestone_cacert.pem':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => hiera('limestone_ssl_cert_file_contents'),
    require => Class['::openstack_project::puppetmaster'],
  }
}

# Node-OS: trusty
# Node-OS: xenial
node /^graphite\d*\.openstack\.org$/ {
  class { 'openstack_project::server':
    sysadmins                 => hiera('sysadmins', []),
    iptables_public_tcp_ports => [80, 443],
    iptables_allowed_hosts    => [
      {protocol => 'udp', port => '8125', hostname => 'git.openstack.org'},
      {protocol => 'udp', port => '8125', hostname => 'firehose01.openstack.org'},
      {protocol => 'udp', port => '8125', hostname => 'mirror-update01.openstack.org'},
      {protocol => 'udp', port => '8125', hostname => 'logstash.openstack.org'},
      {protocol => 'udp', port => '8125', hostname => 'nodepool.openstack.org'},
      {protocol => 'udp', port => '8125', hostname => 'nl01.openstack.org'},
      {protocol => 'udp', port => '8125', hostname => 'nl02.openstack.org'},
      {protocol => 'udp', port => '8125', hostname => 'nl03.openstack.org'},
      {protocol => 'udp', port => '8125', hostname => 'nl04.openstack.org'},
      {protocol => 'udp', port => '8125', hostname => 'zuul01.openstack.org'},
      {protocol => 'udp', port => '8125', hostname => 'zm01.openstack.org'},
      {protocol => 'udp', port => '8125', hostname => 'zm02.openstack.org'},
      {protocol => 'udp', port => '8125', hostname => 'zm03.openstack.org'},
      {protocol => 'udp', port => '8125', hostname => 'zm04.openstack.org'},
      {protocol => 'udp', port => '8125', hostname => 'zm05.openstack.org'},
      {protocol => 'udp', port => '8125', hostname => 'zm06.openstack.org'},
      {protocol => 'udp', port => '8125', hostname => 'zm07.openstack.org'},
      {protocol => 'udp', port => '8125', hostname => 'zm08.openstack.org'},
      {protocol => 'udp', port => '8125', hostname => 'ze01.openstack.org'},
      {protocol => 'udp', port => '8125', hostname => 'ze02.openstack.org'},
      {protocol => 'udp', port => '8125', hostname => 'ze03.openstack.org'},
      {protocol => 'udp', port => '8125', hostname => 'ze04.openstack.org'},
      {protocol => 'udp', port => '8125', hostname => 'ze05.openstack.org'},
      {protocol => 'udp', port => '8125', hostname => 'ze06.openstack.org'},
      {protocol => 'udp', port => '8125', hostname => 'ze07.openstack.org'},
      {protocol => 'udp', port => '8125', hostname => 'ze08.openstack.org'},
      {protocol => 'udp', port => '8125', hostname => 'ze09.openstack.org'},
      {protocol => 'udp', port => '8125', hostname => 'ze10.openstack.org'},
      {protocol => 'udp', port => '8125', hostname => 'ze11.openstack.org'},
    ],
  }

  class { '::graphite':
    graphite_admin_user     => hiera('graphite_admin_user', 'username'),
    graphite_admin_email    => hiera('graphite_admin_email', 'email@example.com'),
    graphite_admin_password => hiera('graphite_admin_password'),
  }
}

# Node-OS: trusty
# Node-OS: xenial
node /^groups\d*\.openstack\.org$/ {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443],
  }
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
node /^groups-dev\d*\.openstack\.org$/ {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443],
  }
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
node /^lists\d*\.openstack\.org$/ {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [25, 80, 465],
    manage_exim => false,
  }

  class { 'openstack_project::lists':
    listadmins   => hiera('listadmins', []),
    listpassword => hiera('listpassword'),
  }
}

# Node-OS: xenial
node /^lists\d*\.katacontainers\.io$/ {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [25, 80, 465],
    manage_exim => false,
  }

  class { 'openstack_project::kata_lists':
    listadmins   => hiera('listadmins', []),
    listpassword => hiera('listpassword'),
  }
}

# Node-OS: xenial
node /^paste\d*\.openstack\.org$/ {
  $group = "paste"

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
  }
  class { 'openstack_project::paste':
    db_password         => hiera('paste_db_password'),
    db_host             => hiera('paste_db_host'),
    vhost_name          => 'paste.openstack.org',
  }
}

# Node-OS: xenial
node /planet\d*\.openstack\.org$/ {
  class { 'openstack_project::planet':
  }
}

# Node-OS: xenial
node /^eavesdrop\d*\.openstack\.org$/ {
  $group = "eavesdrop"
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
  }

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

# Node-OS: trusty
# Node-OS: xenial
node /^ethercalc\d+\.openstack\.org$/ {
  $group = "ethercalc"
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443],
  }

  class { 'openstack_project::ethercalc':
    vhost_name              => 'ethercalc.openstack.org',
    ssl_cert_file_contents  => hiera('ssl_cert_file_contents'),
    ssl_key_file_contents   => hiera('ssl_key_file_contents'),
    ssl_chain_file_contents => hiera('ssl_chain_file_contents'),
  }
}

# Node-OS: trusty
# Node-OS: xenial
node /^etherpad\d*\.openstack\.org$/ {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443],
  }

  class { 'openstack_project::etherpad':
    ssl_cert_file_contents  => hiera('etherpad_ssl_cert_file_contents'),
    ssl_key_file_contents   => hiera('etherpad_ssl_key_file_contents'),
    ssl_chain_file_contents => hiera('etherpad_ssl_chain_file_contents'),
    mysql_host              => hiera('etherpad_db_host', 'localhost'),
    mysql_user              => hiera('etherpad_db_user', 'username'),
    mysql_password          => hiera('etherpad_db_password'),
  }
}

# Node-OS: trusty
# Node-OS: xenial
node /^etherpad-dev\d*\.openstack\.org$/ {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443],
  }

  class { 'openstack_project::etherpad_dev':
    mysql_host          => hiera('etherpad-dev_db_host', 'localhost'),
    mysql_user          => hiera('etherpad-dev_db_user', 'username'),
    mysql_password      => hiera('etherpad-dev_db_password'),
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

# Node-OS: trusty
# Node-OS: xenial
node /^logstash\d*\.openstack\.org$/ {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 3306],
    iptables_allowed_hosts    => hiera_array('logstash_iptables_rule_data'),
  }

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
node /^logstash-worker\d+\.openstack\.org$/ {
  $group = 'logstash-worker'

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22],
  }

  class { 'openstack_project::logstash_worker':
    discover_node         => 'elasticsearch03.openstack.org',
    enable_mqtt           => false,
    mqtt_password         => hiera('mqtt_service_user_password'),
    mqtt_ca_cert_contents => hiera('mosquitto_tls_ca_file'),
  }
}

# Node-OS: xenial
node /^subunit-worker\d+\.openstack\.org$/ {
  $group = "subunit-worker"
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22],
  }
  class { 'openstack_project::subunit_worker':
    subunit2sql_db_host   => hiera('subunit2sql_db_host', ''),
    subunit2sql_db_pass   => hiera('subunit2sql_db_password', ''),
    mqtt_pass             => hiera('mqtt_service_user_password'),
    mqtt_ca_cert_contents => hiera('mosquitto_tls_ca_file'),
  }
}

# Node-OS: xenial
node /^elasticsearch0[1-7]\.openstack\.org$/ {
  $group = "elasticsearch"
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22],
    iptables_allowed_hosts    => hiera_array('elasticsearch_iptables_rule_data'),
  }
  class { 'openstack_project::elasticsearch_node':
    discover_nodes => $elasticsearch_nodes,
  }
}

# Node-OS: xenial
node /^firehose\d+\.openstack\.org$/ {
  class { 'openstack_project::server':
    # NOTE(mtreinish) Port 80 and 8080 are disabled because websocket
    # connections seem to crash mosquitto. Once this is fixed we should add
    # them back
    iptables_public_tcp_ports => [22, 25, 80, 1883, 8883, 443],
    manage_exim               => false,
  }
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
node /^git(-fe\d+)?\.openstack\.org$/ {
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
node /^git\d+\.openstack\.org$/ {
  $group = "git-server"
  include openstack_project
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [4443, 8080, 29418],
  }

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
node /^mirror-update\d*\.openstack\.org$/ {
  $group = "afsadmin"

  class { 'openstack_project::mirror_update':
    bandersnatch_keytab   => hiera('bandersnatch_keytab'),
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
node /^mirror\d*\..*\.openstack\.org$/ {
  $group = "mirror"

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 8080, 8081, 8082],
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
node /^files\d*\.openstack\.org$/ {
  $group = "files"
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
    afs                       => true,
    afs_cache_size            => 10000000,  # 10GB
  }

  class { 'openstack_project::files':
    vhost_name                    => 'files.openstack.org',
    developer_cert_file_contents  => hiera('developer_cert_file_contents'),
    developer_key_file_contents   => hiera('developer_key_file_contents'),
    developer_chain_file_contents => hiera('developer_chain_file_contents'),
    docs_cert_file_contents       => hiera('docs_cert_file_contents'),
    docs_key_file_contents        => hiera('docs_key_file_contents'),
    docs_chain_file_contents      => hiera('docs_chain_file_contents'),
    require                       => Class['Openstack_project::Server'],
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
node /^refstack\d*\.openstack\.org$/ {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
  }
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
# Node-OS: trusty
# Node-OS: xenial
node /^storyboard\d*\.openstack\.org$/ {
  class { 'openstack_project::storyboard':
    project_config_repo     => 'https://git.openstack.org/openstack-infra/project-config',
    sysadmins               => hiera('sysadmins', []),
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
    hostname                => $::fqdn,
    valid_oauth_clients     => [
      $::fqdn,
      'logs.openstack.org',
    ],
    cors_allowed_origins     => [
      "https://${::fqdn}",
      'http://logs.openstack.org',
    ],
    sender_email_address => 'storyboard@storyboard.openstack.org',
    default_url          => 'https://storyboard.openstack.org',
  }
}

# A machine to run Storyboard devel
# Node-OS: trusty
# Node-OS: xenial
node /^storyboard-dev\d*\.openstack\.org$/ {
  class { 'openstack_project::storyboard::dev':
    project_config_repo     => 'https://git.openstack.org/openstack-infra/project-config',
    sysadmins               => hiera('sysadmins', []),
    mysql_host              => hiera('storyboard_db_host', 'localhost'),
    mysql_user              => hiera('storyboard_db_user', 'username'),
    mysql_password          => hiera('storyboard_db_password'),
    rabbitmq_user           => hiera('storyboard_rabbit_user', 'username'),
    rabbitmq_password       => hiera('storyboard_rabbit_password'),
    hostname                => $::fqdn,
    valid_oauth_clients     => [
      $::fqdn,
      'logs.openstack.org',
    ],
    cors_allowed_origins     => [
      "https://${::fqdn}",
      'http://logs.openstack.org',
    ],
    sender_email_address => 'storyboard-dev@storyboard-dev.openstack.org',
    default_url          => 'https://storyboard-dev.openstack.org',
  }

}

# A machine to serve static content.
# Node-OS: trusty
# Node-OS: xenial
node /^static\d*\.openstack\.org$/ {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443],
  }
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
node /^zk\d+\.openstack\.org$/ {
  class { 'openstack_project::server':
    iptables_allowed_hosts    => [
      # Zookeeper clients
      {protocol => 'tcp', port => '2181', hostname => 'nb01.openstack.org'},
      {protocol => 'tcp', port => '2181', hostname => 'nb02.openstack.org'},
      {protocol => 'tcp', port => '2181', hostname => 'nb03.openstack.org'},
      {protocol => 'tcp', port => '2181', hostname => 'nl01.openstack.org'},
      {protocol => 'tcp', port => '2181', hostname => 'nl02.openstack.org'},
      {protocol => 'tcp', port => '2181', hostname => 'nl03.openstack.org'},
      {protocol => 'tcp', port => '2181', hostname => 'nl04.openstack.org'},
      {protocol => 'tcp', port => '2181', hostname => 'zuul01.openstack.org'},
      # Zookeeper election
      {protocol => 'tcp', port => '2888', hostname => 'zk01.openstack.org'},
      {protocol => 'tcp', port => '2888', hostname => 'zk02.openstack.org'},
      {protocol => 'tcp', port => '2888', hostname => 'zk03.openstack.org'},
      # Zookeeper leader
      {protocol => 'tcp', port => '3888', hostname => 'zk01.openstack.org'},
      {protocol => 'tcp', port => '3888', hostname => 'zk02.openstack.org'},
      {protocol => 'tcp', port => '3888', hostname => 'zk03.openstack.org'},
    ],
  }

  class { '::zookeeper':
    # ID needs to be numeric, so we use regex to extra numbers from fqdn.
    id             => regsubst($::fqdn, '^zk(\d+)\.openstack\.org$', '\1'),
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
node /^status\d*\.openstack\.org$/ {
  $group = 'status'

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443],
  }

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
node /^survey\d+\.openstack\.org$/ {
  $group = "survey"
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443],
  }

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

# This is a hidden authoritative master nameserver, not publicly
# accessible.
# Node-OS: xenial
node /^adns\d+\.openstack\.org$/ {
  $group = 'adns'

  class { 'openstack_project::server':
    iptables_allowed_hosts    => [
      {protocol => 'tcp', port => '53', hostname => 'ns1.openstack.org'},
      {protocol => 'tcp', port => '53', hostname => 'ns2.openstack.org'},
    ],
  }

  class { 'openstack_project::master_nameserver':
    tsig_key => hiera('tsig_key', {}),
    dnssec_keys => hiera_hash('dnssec_keys', {}),
    notifies => concat(dns_a('ns1.openstack.org'), dns_a('ns2.openstack.org')),
  }
}

# These are publicly accessible authoritative slave nameservers.
# Node-OS: xenial
node /^ns\d+\.openstack\.org$/ {
  $group = 'ns'

  class { 'openstack_project::server':
    iptables_public_udp_ports => [53],
    iptables_public_tcp_ports => [53],
  }

  $tsig_key = hiera('tsig_key', {})
  if $tsig_key != {} {
    $tsig_name = 'tsig'
    nsd::tsig { 'tsig':
      algo => $tsig_key[algorithm],
      data => $tsig_key[secret],
    }
  } else {
    $tsig_name = undef
  }

  class { '::nsd':
    ip_addresses => [ $::ipaddress, $::ipaddress6 ],
    zones => {
      'adns1_zones' => {
        allow_notify => dns_a('adns1.openstack.org'),
        masters => dns_a('adns1.openstack.org'),
        zones => ['zuul-ci.org', 'zuulci.org'],
        tsig_name => $tsig_name,
      }
    }
  }
}

# Node-OS: trusty
node 'nodepool.openstack.org' {
  $group = 'nodepool'
  # TODO(pabelanger): Move all of this back into nodepool manifest, it has
  # grown too big.
  $rackspace_username             = hiera('nodepool_rackspace_username', 'username')
  $rackspace_password             = hiera('nodepool_rackspace_password')
  $rackspace_project              = hiera('nodepool_rackspace_project', 'project')
  $hpcloud_username               = hiera('nodepool_hpcloud_username', 'username')
  $hpcloud_password               = hiera('nodepool_hpcloud_password')
  $hpcloud_project                = hiera('nodepool_hpcloud_project', 'project')
  $internap_username              = hiera('nodepool_internap_username', 'username')
  $internap_password              = hiera('nodepool_internap_password')
  $internap_project               = hiera('nodepool_internap_project', 'project')
  $ovh_username                   = hiera('nodepool_ovh_username', 'username')
  $ovh_password                   = hiera('nodepool_ovh_password')
  $ovh_project                    = hiera('nodepool_ovh_project', 'project')
  $tripleo_username               = hiera('nodepool_tripleo_username', 'username')
  $tripleo_password               = hiera('nodepool_tripleo_password')
  $tripleo_project                = hiera('nodepool_tripleo_project', 'project')
  $vexxhost_username              = hiera('nodepool_vexxhost_username', 'username')
  $vexxhost_password              = hiera('nodepool_vexxhost_password')
  $vexxhost_project               = hiera('nodepool_vexxhost_project', 'project')
  $citycloud_username             = hiera('nodepool_citycloud_username', 'username')
  $citycloud_password             = hiera('nodepool_citycloud_password')
  $linaro_username                = hiera('nodepool_linaro_username', 'username')
  $linaro_password                = hiera('nodepool_linaro_password')
  $linaro_project                 = hiera('nodepool_linaro_project', 'project')
  $limestone_username             = hiera('nodepool_limestone_username', 'username')
  $limestone_password             = hiera('nodepool_limestone_password')
  $limestone_project              = hiera('nodepool_limestone_project', 'project')

  $clouds_yaml = template("openstack_project/nodepool/clouds.yaml.erb")

  class { 'openstack_project::server':
    iptables_allowed_hosts    => [
      {protocol => 'tcp', port => '2181', hostname => 'nb01.openstack.org'},
      {protocol => 'tcp', port => '2181', hostname => 'nb02.openstack.org'},
      {protocol => 'tcp', port => '2181', hostname => 'nb03.openstack.org'},
      {protocol => 'tcp', port => '2181', hostname => 'nl01.openstack.org'},
      {protocol => 'tcp', port => '2181', hostname => 'nl02.openstack.org'},
      {protocol => 'tcp', port => '2181', hostname => 'nl03.openstack.org'},
      {protocol => 'tcp', port => '2181', hostname => 'nl04.openstack.org'},
      {protocol => 'tcp', port => '2181', hostname => 'zuul01.openstack.org'},
    ],
    iptables_public_tcp_ports => [80],
  }

  class { '::zookeeper':
    # The frequency in hours to look for and purge old snapshots,
    # defaults to 0 (disabled). The number of retained snapshots can
    # be separately controlled through snap_retain_count and
    # defaults to the minimum value of 3. This will quickly fill the
    # disk in production if not enabled. Works on ZK >=3.4.
    purge_interval => 6,
  }

  include openstack_project

  class { '::openstackci::nodepool':
    vhost_name                    => 'nodepool.openstack.org',
    project_config_repo           => 'https://git.openstack.org/openstack-infra/project-config',
    mysql_password                => hiera('nodepool_mysql_password'),
    mysql_root_password           => hiera('nodepool_mysql_root_password'),
    nodepool_ssh_public_key       => hiera('zuul_worker_ssh_public_key_contents'),
    # TODO(pabelanger): Switch out private key with zuul_worker once we are
    # ready.
    nodepool_ssh_private_key      => hiera('jenkins_ssh_private_key_contents'),
    oscc_file_contents            => $clouds_yaml,
    image_log_document_root       => '/var/log/nodepool/image',
    statsd_host                   => 'graphite.openstack.org',
    logging_conf_template         => 'openstack_project/nodepool/nodepool.logging.conf.erb',
    builder_logging_conf_template => 'openstack_project/nodepool/nodepool-builder.logging.conf.erb',
    upload_workers                => '16',
    jenkins_masters               => [],
    split_daemon                  => true,
  }
  file { '/home/nodepool/.config/openstack/limestone_cacert.pem':
    ensure  => present,
    owner   => 'nodepool',
    group   => 'nodepool',
    mode    => '0600',
    content => hiera('limestone_ssl_cert_file_contents'),
    require => Class['::openstackci::nodepool'],
  }

  cron { 'mirror_gitgc':
    user        => 'nodepool',
    hour        => '20',
    minute      => '0',
    command     => 'find /opt/dib_cache/source-repositories/ -maxdepth 1 -type d -name "*.git" -exec git --git-dir="{}" gc \; >/dev/null',
    environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
    require     => Class['::openstackci::nodepool'],
  }
}

# Node-OS: xenial
node /^nl\d+\.openstack\.org$/ {
  $group = 'nodepool'
  # TODO(pabelanger): Move all of this back into nodepool manifest, it has
  # grown too big.
  $rackspace_username             = hiera('nodepool_rackspace_username', 'username')
  $rackspace_password             = hiera('nodepool_rackspace_password')
  $rackspace_project              = hiera('nodepool_rackspace_project', 'project')
  $hpcloud_username               = hiera('nodepool_hpcloud_username', 'username')
  $hpcloud_password               = hiera('nodepool_hpcloud_password')
  $hpcloud_project                = hiera('nodepool_hpcloud_project', 'project')
  $internap_username              = hiera('nodepool_internap_username', 'username')
  $internap_password              = hiera('nodepool_internap_password')
  $internap_project               = hiera('nodepool_internap_project', 'project')
  $ovh_username                   = hiera('nodepool_ovh_username', 'username')
  $ovh_password                   = hiera('nodepool_ovh_password')
  $ovh_project                    = hiera('nodepool_ovh_project', 'project')
  $tripleo_username               = hiera('nodepool_tripleo_username', 'username')
  $tripleo_password               = hiera('nodepool_tripleo_password')
  $tripleo_project                = hiera('nodepool_tripleo_project', 'project')
  $vexxhost_username              = hiera('nodepool_vexxhost_username', 'username')
  $vexxhost_password              = hiera('nodepool_vexxhost_password')
  $vexxhost_project               = hiera('nodepool_vexxhost_project', 'project')
  $citycloud_username             = hiera('nodepool_citycloud_username', 'username')
  $citycloud_password             = hiera('nodepool_citycloud_password')
  $linaro_username                = hiera('nodepool_linaro_username', 'username')
  $linaro_password                = hiera('nodepool_linaro_password')
  $linaro_project                 = hiera('nodepool_linaro_project', 'project')
  $limestone_username             = hiera('nodepool_limestone_username', 'username')
  $limestone_password             = hiera('nodepool_limestone_password')
  $limestone_project              = hiera('nodepool_limestone_project', 'project')
  $packethost_username            = hiera('nodepool_packethost_username', 'username')
  $packethost_password            = hiera('nodepool_packethost_password')
  $packethost_project             = hiera('nodepool_packethost_project', 'project')
  $clouds_yaml                    = template("openstack_project/nodepool/clouds.yaml.erb")

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
  }

  include openstack_project

  class { '::openstackci::nodepool_launcher':
    nodepool_ssh_private_key => hiera('zuul_worker_ssh_private_key_contents'),
    project_config_repo      => 'https://git.openstack.org/openstack-infra/project-config',
    oscc_file_contents       => $clouds_yaml,
    statsd_host              => 'graphite.openstack.org',
    revision                 => 'master',
    python_version           => 3,
    enable_webapp            => true,
  }

  file { '/home/nodepool/.config/openstack/limestone_cacert.pem':
    ensure  => present,
    owner   => 'nodepool',
    group   => 'nodepool',
    mode    => '0600',
    content => hiera('limestone_ssl_cert_file_contents'),
    require => Class['::openstackci::nodepool_launcher'],
  }
}

# Node-OS: xenial
node /^nb\d+\.openstack\.org$/ {
  $group = 'nodepool'
  # TODO(pabelanger): Move all of this back into nodepool manifest, it has
  # grown too big.
  $rackspace_username            = hiera('nodepool_rackspace_username', 'username')
  $rackspace_password            = hiera('nodepool_rackspace_password')
  $rackspace_project             = hiera('nodepool_rackspace_project', 'project')
  $hpcloud_username              = hiera('nodepool_hpcloud_username', 'username')
  $hpcloud_password              = hiera('nodepool_hpcloud_password')
  $hpcloud_project               = hiera('nodepool_hpcloud_project', 'project')
  $internap_username             = hiera('nodepool_internap_username', 'username')
  $internap_password             = hiera('nodepool_internap_password')
  $internap_project              = hiera('nodepool_internap_project', 'project')
  $ovh_username                  = hiera('nodepool_ovh_username', 'username')
  $ovh_password                  = hiera('nodepool_ovh_password')
  $ovh_project                   = hiera('nodepool_ovh_project', 'project')
  $tripleo_username              = hiera('nodepool_tripleo_username', 'username')
  $tripleo_password              = hiera('nodepool_tripleo_password')
  $tripleo_project               = hiera('nodepool_tripleo_project', 'project')
  $vexxhost_username             = hiera('nodepool_vexxhost_username', 'username')
  $vexxhost_password             = hiera('nodepool_vexxhost_password')
  $vexxhost_project              = hiera('nodepool_vexxhost_project', 'project')
  $citycloud_username            = hiera('nodepool_citycloud_username', 'username')
  $citycloud_password            = hiera('nodepool_citycloud_password')
  $linaro_username               = hiera('nodepool_linaro_username', 'username')
  $linaro_password               = hiera('nodepool_linaro_password')
  $linaro_project                = hiera('nodepool_linaro_project', 'project')
  $limestone_username            = hiera('nodepool_limestone_username', 'username')
  $limestone_password            = hiera('nodepool_limestone_password')
  $limestone_project             = hiera('nodepool_limestone_project', 'project')
  $packethost_username            = hiera('nodepool_packethost_username', 'username')
  $packethost_password            = hiera('nodepool_packethost_password')
  $packethost_project             = hiera('nodepool_packethost_project', 'project')
  $clouds_yaml                   = template("openstack_project/nodepool/clouds.yaml.erb")

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
  }

  include openstack_project

  class { '::openstackci::nodepool_builder':
    nodepool_ssh_public_key       => hiera('zuul_worker_ssh_public_key_contents'),
    vhost_name                    => $::fqdn,
    enable_build_log_via_http     => true,
    project_config_repo           => 'https://git.openstack.org/openstack-infra/project-config',
    oscc_file_contents            => $clouds_yaml,
    statsd_host                   => 'graphite.openstack.org',
    builder_logging_conf_template => 'openstack_project/nodepool/nodepool-builder.logging.conf.erb',
    upload_workers                => '16',
    revision                      => 'master',
    python_version                => 3,
    zuulv3                        => true,
    ssl_cert_file                 => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
    ssl_key_file                  => '/etc/ssl/private/ssl-cert-snakeoil.key',
  }

  file { '/home/nodepool/.config/openstack/limestone_cacert.pem':
    ensure  => present,
    owner   => 'nodepool',
    group   => 'nodepool',
    mode    => '0600',
    content => hiera('limestone_ssl_cert_file_contents'),
    require => Class['::openstackci::nodepool_builder'],
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
node /^ze\d+\.openstack\.org$/ {
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
    iptables_public_tcp_ports => [79, 7900],
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
    zookeeper_hosts          => 'nodepool.openstack.org:2181',
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
node /^zuul\d+\.openstack\.org$/ {
  $group = "zuul-scheduler"
  $gerrit_server        = 'review.openstack.org'
  $gerrit_user          = 'zuul'
  $gerrit_ssh_host_key  = hiera('gerrit_zuul_user_ssh_key_contents')
  $zuul_ssh_private_key = hiera('zuul_ssh_private_key_contents')
  $zuul_url             = "http://zuul.openstack.org/p"
  $git_email            = 'zuul@openstack.org'
  $git_name             = 'OpenStack Zuul'
  $revision             = 'master'

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [79, 80, 443],
    iptables_allowed_hosts    => [
      {protocol => 'tcp', port => '4730', hostname => 'ze01.openstack.org'},
      {protocol => 'tcp', port => '4730', hostname => 'ze02.openstack.org'},
      {protocol => 'tcp', port => '4730', hostname => 'ze03.openstack.org'},
      {protocol => 'tcp', port => '4730', hostname => 'ze04.openstack.org'},
      {protocol => 'tcp', port => '4730', hostname => 'ze05.openstack.org'},
      {protocol => 'tcp', port => '4730', hostname => 'ze06.openstack.org'},
      {protocol => 'tcp', port => '4730', hostname => 'ze07.openstack.org'},
      {protocol => 'tcp', port => '4730', hostname => 'ze08.openstack.org'},
      {protocol => 'tcp', port => '4730', hostname => 'ze09.openstack.org'},
      {protocol => 'tcp', port => '4730', hostname => 'ze10.openstack.org'},
      {protocol => 'tcp', port => '4730', hostname => 'ze11.openstack.org'},
      {protocol => 'tcp', port => '4730', hostname => 'zm01.openstack.org'},
      {protocol => 'tcp', port => '4730', hostname => 'zm02.openstack.org'},
      {protocol => 'tcp', port => '4730', hostname => 'zm03.openstack.org'},
      {protocol => 'tcp', port => '4730', hostname => 'zm04.openstack.org'},
      {protocol => 'tcp', port => '4730', hostname => 'zm05.openstack.org'},
      {protocol => 'tcp', port => '4730', hostname => 'zm06.openstack.org'},
      {protocol => 'tcp', port => '4730', hostname => 'zm07.openstack.org'},
      {protocol => 'tcp', port => '4730', hostname => 'zm08.openstack.org'},
    ],
  }

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
    zookeeper_hosts               => 'nodepool.openstack.org:2181',
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
    tenant_name             => 'openstack',
    vhost_name              => 'zuul.openstack.org',
    ssl_cert_file_contents  => hiera('zuul_ssl_cert_file_contents'),
    ssl_chain_file_contents => hiera('zuul_ssl_chain_file_contents'),
    ssl_key_file_contents   => hiera('zuul_ssl_key_file_contents'),
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
node /^zm\d+.openstack\.org$/ {
  $group = "zuul-merger"

  $gerrit_server        = 'review.openstack.org'
  $gerrit_user          = 'zuul'
  $gerrit_ssh_host_key  = hiera('gerrit_ssh_rsa_pubkey_contents')
  $zuul_ssh_private_key = hiera('zuulv3_ssh_private_key_contents')
  $zuul_url             = "http://${::fqdn}/p"
  $git_email            = 'zuul@openstack.org'
  $git_name             = 'OpenStack Zuul'
  $revision             = 'master'

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
  }

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
    zookeeper_hosts         => 'nodepool.openstack.org:2181',
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

# Node-OS: trusty
node 'pbx.openstack.org' {
  class { 'openstack_project::server':
    # SIP signaling is either TCP or UDP port 5060.
    # RTP media (audio/video) uses a range of UDP ports.
    iptables_public_tcp_ports => [5060],
    iptables_public_udp_ports => ['5060', '10000:20000'],
  }
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
node /^backup\d+\..*\.ci\.openstack\.org$/ {
  $group = "ci-backup"
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [],
    manage_exim => false,
  }
  include openstack_project::backup_server
}

# Node-OS: trusty
node 'openstackid.org' {
  class { 'openstack_project::openstackid_prod':
    site_admin_password         => hiera('openstackid_site_admin_password'),
    id_mysql_host               => hiera('openstackid_id_mysql_host', 'localhost'),
    id_mysql_password           => hiera('openstackid_id_mysql_password'),
    id_mysql_user               => hiera('openstackid_id_mysql_user', 'username'),
    id_db_name                  => hiera('openstackid_id_db_name'),
    ss_mysql_host               => hiera('openstackid_ss_mysql_host', 'localhost'),
    ss_mysql_password           => hiera('openstackid_ss_mysql_password'),
    ss_mysql_user               => hiera('openstackid_ss_mysql_user', 'username'),
    ss_db_name                  => hiera('openstackid_ss_db_name', 'username'),
    redis_password              => hiera('openstackid_redis_password'),
    ssl_cert_file_contents      => hiera('openstackid_ssl_cert_file_contents'),
    ssl_key_file_contents       => hiera('openstackid_ssl_key_file_contents'),
    ssl_chain_file_contents     => hiera('openstackid_ssl_chain_file_contents'),
    id_recaptcha_public_key     => hiera('openstackid_recaptcha_public_key'),
    id_recaptcha_private_key    => hiera('openstackid_recaptcha_private_key'),
    app_url                     => 'https://openstackid.org',
    app_key                     => hiera('openstackid_app_key'),
    id_log_error_to_email       => 'openstack@tipit.net',
    id_log_error_from_email     => 'noreply@openstack.org',
    email_driver                => 'smtp',
    email_smtp_server           => 'smtp.sendgrid.net',
    email_smtp_server_user      => hiera('openstackid_smtp_user'),
    email_smtp_server_password  => hiera('openstackid_smtp_password'),
  }
}

# Node-OS: trusty
node 'openstackid-dev.openstack.org' {
  class { 'openstack_project::openstackid_dev':
    site_admin_password         => hiera('openstackid_dev_site_admin_password'),
    id_mysql_host               => hiera('openstackid_dev_id_mysql_host', 'localhost'),
    id_mysql_password           => hiera('openstackid_dev_id_mysql_password'),
    id_mysql_user               => hiera('openstackid_dev_id_mysql_user', 'username'),
    ss_mysql_host               => hiera('openstackid_dev_ss_mysql_host', 'localhost'),
    ss_mysql_password           => hiera('openstackid_dev_ss_mysql_password'),
    ss_mysql_user               => hiera('openstackid_dev_ss_mysql_user', 'username'),
    ss_db_name                  => hiera('openstackid_dev_ss_db_name', 'username'),
    redis_password              => hiera('openstackid_dev_redis_password'),
    ssl_cert_file_contents      => hiera('openstackid_dev_ssl_cert_file_contents'),
    ssl_key_file_contents       => hiera('openstackid_dev_ssl_key_file_contents'),
    ssl_chain_file_contents     => hiera('openstackid_dev_ssl_chain_file_contents'),
    id_recaptcha_public_key     => hiera('openstackid_dev_recaptcha_public_key'),
    id_recaptcha_private_key    => hiera('openstackid_dev_recaptcha_private_key'),
    app_url                     => 'https://openstackid-dev.openstack.org',
    app_key                     => hiera('openstackid_dev_app_key'),
    id_log_error_to_email       => 'openstack@tipit.net',
    id_log_error_from_email     => 'noreply@openstack.org',
    email_driver                => 'smtp',
    email_smtp_server           => 'smtp.sendgrid.net',
    email_smtp_server_user      => hiera('openstackid_dev_smtp_user'),
    email_smtp_server_password  => hiera('openstackid_dev_smtp_password'),
  }
}

# Node-OS: trusty
# Used for testing all-in-one deployments
node 'single-node-ci.test.only' {
  include ::openstackci::single_node_ci
}

# Node-OS: trusty
node 'kdc01.openstack.org' {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [88, 464, 749, 754],
    iptables_public_udp_ports => [88, 464, 749],
  }

  class { 'openstack_project::kdc': }
}

# Node-OS: xenial
node 'kdc04.openstack.org' {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [88, 464, 749, 754],
    iptables_public_udp_ports => [88, 464, 749],
  }

  class { 'openstack_project::kdc':
    slave => true,
  }
}

# Node-OS: trusty
node 'afsdb01.openstack.org' {
  $group = "afsdb"

  class { 'openstack_project::server':
    iptables_public_udp_ports => [7000,7002,7003,7004,7005,7006,7007],
    afs                       => true,
    manage_exim               => true,
  }

  include openstack_project::afsdb
  include openstack_project::afsrelease
}

# Node-OS: trusty
node /^afsdb.*\.openstack\.org$/ {
  $group = "afsdb"

  class { 'openstack_project::server':
    iptables_public_udp_ports => [7000,7002,7003,7004,7005,7006,7007],
    afs                       => true,
    manage_exim               => true,
  }

  include openstack_project::afsdb
}

# Node-OS: trusty
node /^afs.*\..*\.openstack\.org$/ {
  $group = "afs"

  class { 'openstack_project::server':
    iptables_public_udp_ports => [7000,7002,7003,7004,7005,7006,7007],
    afs                       => true,
    manage_exim               => true,
  }

  include openstack_project::afsfs
}

# Node-OS: trusty
node 'ask.openstack.org' {

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443],
  }

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
node 'ask-staging.openstack.org' {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443],
  }

  class { 'openstack_project::ask_staging':
    db_password                  => hiera('ask_staging_db_password'),
    redis_password               => hiera('ask_staging_redis_password'),
  }
}

# Node-OS: trusty
# Node-OS: xenial
node /^translate\d+\.openstack\.org$/ {
  $group = "translate"
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
  }
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

# Node-OS: trusty
# Node-OS: xenial
node /^translate-dev\d*\.openstack\.org$/ {
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


# Node-OS: trusty
node 'odsreg.openstack.org' {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
  }
  realize (
    User::Virtual::Localuser['ttx'],
  )
  class { '::odsreg':
  }
}

# Node-OS: trusty
# Node-OS: xenial
node /^codesearch\d*\.openstack\.org$/ {
  $group = "codesearch"
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
  }
  class { 'openstack_project::codesearch':
    project_config_repo => 'https://git.openstack.org/openstack-infra/project-config',
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
