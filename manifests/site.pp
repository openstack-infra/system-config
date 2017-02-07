#
# Top-level variables
#
# There must not be any whitespace between this comment and the variables or
# in between any two variables in order for them to be correctly parsed and
# passed around in test.sh
#
$elasticsearch_nodes = hiera_array('elasticsearch_nodes')
$elasticsearch_clients = hiera_array('elasticsearch_clients')

#
# Default: should at least behave like an openstack server
#
node default {
  class { 'openstack_project::server':
    sysadmins => hiera('sysadmins', []),
  }
}

#
# Long lived servers:
#
# Node-OS: trusty
node 'review.openstack.org' {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443, 29418],
    sysadmins                 => hiera('sysadmins', []),
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
    contactstore_appsec                 => hiera('gerrit_contactstore_appsec'),
    contactstore_pubkey                 => hiera('gerrit_contactstore_pubkey'),
    swift_username                      => hiera('swift_store_user', 'username'),
    swift_password                      => hiera('swift_store_key'),
    storyboard_password                 => hiera('gerrit_storyboard_token'),
  }
}

# Node-OS: trusty
node 'review-dev.openstack.org' {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443, 29418],
    sysadmins                 => hiera('sysadmins', []),
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
    contactstore_appsec                 => hiera('gerrit_dev_contactstore_appsec'),
    contactstore_pubkey                 => hiera('gerrit_dev_contactstore_pubkey'),
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

# Node-OS: trusty
node 'grafana.openstack.org' {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
    sysadmins                 => hiera('sysadmins', []),
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
node 'health.openstack.org' {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
    sysadmins                 => hiera('sysadmins', []),
  }
  class { 'openstack_project::openstack_health_api':
    subunit2sql_db_host => hiera('subunit2sql_db_host', 'localhost'),
  }
}

# Node-OS: trusty
node 'stackalytics.openstack.org' {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
    sysadmins                 => hiera('sysadmins', []),
  }

  class { 'openstack_project::stackalytics':
    gerrit_ssh_user              => hiera('stackalytics_gerrit_ssh_user'),
    stackalytics_ssh_private_key => hiera('stackalytics_ssh_private_key_contents'),
  }
}

# Node-OS: precise
node /^jenkins\d+\.openstack\.org$/ {
  $group = "jenkins"
  $zmq_event_receivers = ['logstash.openstack.org',
                          'nodepool.openstack.org']
  $zmq_iptables_rule = regsubst($zmq_event_receivers,
                                '^(.*)$', '-m state --state NEW -m tcp -p tcp --dport 8888 -s \1 -j ACCEPT')
  $http_iptables_rule = '-m state --state NEW -m tcp -p tcp --dport 80 -s nodepool.openstack.org -j ACCEPT'
  $https_iptables_rule = '-m state --state NEW -m tcp -p tcp --dport 443 -s nodepool.openstack.org -j ACCEPT'
  $iptables_rule = flatten([$zmq_iptables_rule, $http_iptables_rule, $https_iptables_rule])
  class { 'openstack_project::server':
    iptables_rules6     => $iptables_rule,
    iptables_rules4     => $iptables_rule,
    sysadmins           => hiera('sysadmins', []),
    puppetmaster_server => 'puppetmaster.openstack.org',
  }
  class { 'openstack_project::jenkins':
    jenkins_password        => hiera('jenkins_jobs_password'),
    jenkins_ssh_private_key => hiera('jenkins_ssh_private_key_contents'),
    ssl_cert_file           => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
    ssl_key_file            => '/etc/ssl/private/ssl-cert-snakeoil.key',
    ssl_chain_file          => '',
  }
}

# Node-OS: trusty
node 'cacti.openstack.org' {
  include openstack_project::ssl_cert_check
  class { 'openstack_project::cacti':
    sysadmins   => hiera('sysadmins', []),
    cacti_hosts => hiera_array('cacti_hosts'),
    vhost_name  => 'cacti.openstack.org',
  }
}

# Node-OS: trusty
node /^cacti\d+\.openstack\.org$/ {
  $group = "cacti"
  include openstack_project::ssl_cert_check
  class { 'openstack_project::cacti':
    sysadmins   => hiera('sysadmins', []),
    cacti_hosts => hiera_array('cacti_hosts'),
    vhost_name  => 'cacti.openstack.org',
  }
}

# Node-OS: trusty
node 'puppetmaster.openstack.org' {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [8140],
    sysadmins                 => hiera('sysadmins', []),
    pin_puppet                => '3.6.',
  }
  class { 'openstack_project::puppetmaster':
    root_rsa_key                               => hiera('puppetmaster_root_rsa_key'),
    puppetmaster_clouds                        => hiera('puppetmaster_clouds'),
    puppetdb                                   => false,
  }
}

# Node-OS: precise
node 'puppetdb.openstack.org' {
  $open_ports = [8081, 80]
  class { 'openstack_project::server':
    iptables_public_tcp_ports => $open_ports,
    sysadmins                 => hiera('sysadmins', []),
  }
  include openstack_project::puppetdb
}

# Node-OS: trusty
node 'puppetdb01.openstack.org' {
  $open_ports = [8081, 80]
  class { 'openstack_project::server':
    iptables_public_tcp_ports => $open_ports,
    sysadmins                 => hiera('sysadmins', []),
  }
  class { 'openstack_project::puppetdb':
    version => '4.0.2-1puppetlabs1',
  }
}

# Node-OS: trusty
node 'graphite.openstack.org' {
  $statsd_hosts = ['git.openstack.org',
                   'logstash.openstack.org',
                   'nodepool.openstack.org',
                   'zuul.openstack.org']

  # Turn a list of hostnames into a list of iptables rules
  $rules = regsubst ($statsd_hosts, '^(.*)$', '-m udp -p udp -s \1 --dport 8125 -j ACCEPT')

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
    iptables_rules6           => $rules,
    iptables_rules4           => $rules,
    sysadmins                 => hiera('sysadmins', [])
  }

  class { '::graphite':
    graphite_admin_user     => hiera('graphite_admin_user', 'username'),
    graphite_admin_email    => hiera('graphite_admin_email', 'email@example.com'),
    graphite_admin_password => hiera('graphite_admin_password'),
  }
}

# Node-OS: trusty
node 'groups.openstack.org' {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443],
    sysadmins                 => hiera('sysadmins', []),
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
node 'groups-dev.openstack.org' {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443],
    sysadmins                 => hiera('sysadmins', []),
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
node 'lists.openstack.org' {
  class { 'openstack_project::lists':
    listadmins   => hiera('listadmins', []),
    listpassword => hiera('listpassword'),
  }
}

# Node-OS: trusty
node 'paste.openstack.org' {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
    sysadmins                 => hiera('sysadmins', []),
  }
  class { 'openstack_project::paste':
    db_password         => hiera('paste_db_password'),
    db_host             => hiera('paste_db_host'),
  }
}

# Node-OS: trusty
node /^paste\d+\.openstack\.org$/ {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
    sysadmins                 => hiera('sysadmins', []),
  }
  class { 'openstack_project::paste':
    db_password         => hiera('paste_db_password'),
    db_host             => hiera('paste_db_host'),
    vhost_name          => 'paste.openstack.org',
  }
}

# Node-OS: precise
# Node-OS: trusty
node 'planet.openstack.org' {
  class { 'openstack_project::planet':
    sysadmins => hiera('sysadmins', []),
  }
}

# Node-OS: trusty
node 'eavesdrop.openstack.org' {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
    sysadmins                 => hiera('sysadmins', []),
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
    # https://wiki.openstack.org/wiki/Successes
    statusbot_wiki_successpageid => '7717',
    statusbot_irclogs_url   => 'http://eavesdrop.openstack.org/irclogs/%(chan)s/%(chan)s.%(date)s.log.html',
    statusbot_twitter                 => true,
    statusbot_twitter_key             => hiera('statusbot_twitter_key'),
    statusbot_twitter_secret          => hiera('statusbot_twitter_secret'),
    statusbot_twitter_token_key       => hiera('statusbot_twitter_token_key'),
    statusbot_twitter_token_secret    => hiera('statusbot_twitter_token_secret'),
    accessbot_nick          => hiera('accessbot_nick', 'username'),
    accessbot_password      => hiera('accessbot_nick_password'),
    meetbot_channels        => hiera('meetbot_channels', ['openstack-infra']),
  }
}

# Node-OS: trusty
node /^ethercalc\d+\.openstack\.org$/ {
  $group = "ethercalc"
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443],
    sysadmins                 => hiera('sysadmins', []),
  }

  class { 'openstack_project::ethercalc':
    vhost_name              => 'ethercalc.openstack.org',
    ssl_cert_file_contents  => hiera('ssl_cert_file_contents'),
    ssl_key_file_contents   => hiera('ssl_key_file_contents'),
    ssl_chain_file_contents => hiera('ssl_chain_file_contents'),
  }
}

# Node-OS: trusty
node 'etherpad.openstack.org' {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443],
    sysadmins                 => hiera('sysadmins', []),
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
node 'etherpad-dev.openstack.org' {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443],
    sysadmins                 => hiera('sysadmins', []),
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
    sysadmins                 => hiera('sysadmins', []),
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
    sysadmins             => hiera('sysadmins', []),
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
node 'logstash.openstack.org' {
  $iptables_es_rule = regsubst($elasticsearch_nodes,
  '^(.*)$', '-m state --state NEW -m tcp -p tcp --dport 9200:9400 -s \1 -j ACCEPT')
  $iptables_gm_rule = regsubst($elasticsearch_clients,
  '^(.*)$', '-m state --state NEW -m tcp -p tcp --dport 4730 -s \1 -j ACCEPT')
  $logstash_iptables_rule = flatten([$iptables_es_rule, $iptables_gm_rule])

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 3306],
    iptables_rules6           => $logstash_iptables_rule,
    iptables_rules4           => $logstash_iptables_rule,
    sysadmins                 => hiera('sysadmins', []),
  }

  class { 'openstack_project::logstash':
    discover_nodes      => [
      'elasticsearch02.openstack.org:9200',
      'elasticsearch03.openstack.org:9200',
      'elasticsearch04.openstack.org:9200',
      'elasticsearch05.openstack.org:9200',
      'elasticsearch06.openstack.org:9200',
      'elasticsearch07.openstack.org:9200',
    ],
    subunit2sql_db_host => hiera('subunit2sql_db_host', ''),
    subunit2sql_db_pass => hiera('subunit2sql_db_password', ''),
  }
}

# Node-OS: trusty
node /^logstash-worker\d+\.openstack\.org$/ {
  $logstash_worker_iptables_rule = regsubst(flatten([$elasticsearch_nodes, $elasticsearch_clients]),
  '^(.*)$', '-m state --state NEW -m tcp -p tcp --dport 9200:9400 -s \1 -j ACCEPT')
  $group = 'logstash-worker'

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22],
    iptables_rules6           => $logstash_worker_iptables_rule,
    iptables_rules4           => $logstash_worker_iptables_rule,
    sysadmins                 => hiera('sysadmins', []),
  }

  class { 'openstack_project::logstash_worker':
    discover_node         => 'elasticsearch02.openstack.org',
    enable_mqtt           => false,
    mqtt_password         => hiera('mqtt_service_user_password'),
    mqtt_ca_cert_contents => hiera('mosquitto_tls_ca_file'),
  }
}

# Node-OS: trusty
node /^subunit-worker\d+\.openstack\.org$/ {
  $group = "subunit-worker"
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22],
    sysadmins                 => hiera('sysadmins', []),
  }
  class { 'openstack_project::subunit_worker':
    subunit2sql_db_host => hiera('subunit2sql_db_host', ''),
    subunit2sql_db_pass => hiera('subunit2sql_db_password', ''),
  }
}

# Node-OS: trusty
node /^elasticsearch0[1-7]\.openstack\.org$/ {
  $group = "elasticsearch"
  $iptables_nodes_rule = regsubst ($elasticsearch_nodes,
                                   '^(.*)$', '-m state --state NEW -m tcp -p tcp --dport 9200:9400 -s \1 -j ACCEPT')
  $iptables_clients_rule = regsubst ($elasticsearch_clients,
                                     '^(.*)$', '-m state --state NEW -m tcp -p tcp --dport 9200:9400 -s \1 -j ACCEPT')
  $iptables_rule = flatten([$iptables_nodes_rule, $iptables_clients_rule])
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22],
    iptables_rules6           => $iptables_rule,
    iptables_rules4           => $iptables_rule,
    sysadmins                 => hiera('sysadmins', []),
  }
  class { 'openstack_project::elasticsearch_node':
    discover_nodes        => $elasticsearch_nodes,
  }
}

# Node-OS: xenial
node /^firehose\d+\.openstack\.org$/ {
  class { 'openstack_project::server':
    # NOTE(mtreinish) Port 80 and 8080 are disabled because websocket
    # connections seem to crash mosquitto. Once this is fixed we should add
    # them back
    iptables_public_tcp_ports => [22, 25, 1883, 8883],
    sysadmins                 => hiera('sysadmins', []),
    manage_exim               => false,
  }
  class { 'openstack_project::firehose':
    sysadmins           => hiera('sysadmins', []),
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
  }
}

# Node-OS: trusty
node /^pholio\d+\.openstack\.org$/ {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443],
    sysadmins                 => hiera('sysadmins', []),
  }
  class { '::phabricator':
    httpd_admin_email       => hiera('infra_apache_serveradmin'),
    httpd_vhost             => 'pholio.openstack.org',
    mysql_user_password     => hiera('pholio_mysql_user_password'),
    mysql_root_password     => hiera('pholio_mysql_root_password'),
    ssl_cert_file_contents  => hiera('ssl_cert_file_contents'),
    ssl_key_file_contents   => hiera('ssl_key_file_contents'),
    ssl_chain_file_contents => hiera('ssl_chain_file_contents'),
  }
}

# CentOS machines to load balance git access.
# Node-OS: centos7
node /^git(-fe\d+)?\.openstack\.org$/ {
  $group = "git-loadbalancer"
  class { 'openstack_project::git':
    sysadmins               => hiera('sysadmins', []),
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
    sysadmins                 => hiera('sysadmins', []),
  }

  class { 'openstack_project::git_backend':
    project_config_repo     => 'https://git.openstack.org/openstack-infra/project-config',
    vhost_name              => 'git.openstack.org',
    git_gerrit_ssh_key      => hiera('gerrit_replication_ssh_rsa_pubkey_contents'),
    ssl_cert_file_contents  => hiera('git_ssl_cert_file_contents'),
    ssl_key_file_contents   => hiera('git_ssl_key_file_contents'),
    ssl_chain_file_contents => hiera('git_ssl_chain_file_contents'),
    behind_proxy            => true,
    selinux_mode            => 'enforcing'
  }
}

# A machine to drive AFS mirror updates.
# Node-OS: trusty
node 'mirror-update.openstack.org' {
  $group = "afsadmin"

  class { 'openstack_project::mirror_update':
    bandersnatch_keytab => hiera('bandersnatch_keytab'),
    admin_keytab        => hiera('afsadmin_keytab'),
    fedora_keytab       => hiera('fedora_keytab'),
    reprepro_keytab     => hiera('reprepro_keytab'),
    gem_keytab          => hiera('gem_keytab'),
    npm_keytab          => hiera('npm_keytab'),
    centos_keytab       => hiera('centos_keytab'),
    epel_keytab         => hiera('epel_keytab'),
    sysadmins           => hiera('sysadmins', []),
  }
}

# Machines in each region to serve AFS mirrors.
# Node-OS: trusty
node /^mirror\..*\.openstack\.org$/ {
  $group = "mirror"

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80],
    sysadmins                 => hiera('sysadmins', []),
    afs                       => true,
    afs_cache_size            => 50000000,  # 50GB
  }

  class { 'openstack_project::mirror':
    vhost_name => $::fqdn,
    require    => Class['Openstack_project::Server'],
  }
}

# A machine to run ODSREG in preparation for summits.
# Node-OS: trusty
node 'design-summit-prep.openstack.org' {
  class { 'openstack_project::summit':
    sysadmins => hiera('sysadmins', []),
  }
}

# Serve static AFS content for docs and other sites.
# Node-OS: trusty
node 'files01.openstack.org' {
  $group = "files"
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
    sysadmins                 => hiera('sysadmins', []),
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
}

# Node-OS: trusty
node 'refstack.openstack.org' {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
    sysadmins                 => hiera('sysadmins', []),
  }
  class { 'refstack':
    mysql_host          => hiera('refstack_mysql_host', 'localhost'),
    mysql_database      => hiera('refstack_mysql_db_name', 'refstack'),
    mysql_user          => hiera('refstack_mysql_user', 'refstack'),
    mysql_user_password => hiera('refstack_mysql_password'),
    ssl_cert_content    => hiera('refstack_ssl_cert_file_contents'),
    ssl_key_content     => hiera('refstack_ssl_key_file_contents'),
    ssl_ca_content      => hiera('refstack_ssl_chain_file_contents'),
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
node 'storyboard.openstack.org' {
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
      'docs-draft.openstack.org',
    ],
    cors_allowed_origins     => [
      "https://${::fqdn}",
      'http://docs-draft.openstack.org',
    ],
    sender_email_address => 'storyboard@storyboard.openstack.org',
  }
}

# A machine to run Storyboard devel
# Node-OS: trusty
node 'storyboard-dev.openstack.org' {
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
      'docs-draft.openstack.org',
    ],
    cors_allowed_origins     => [
      "https://${::fqdn}",
      'http://docs-draft.openstack.org',
    ],
    sender_email_address => 'storyboard-dev@storyboard-dev.openstack.org',
  }

}

# A machine to serve static content.
# Node-OS: trusty
node 'static.openstack.org' {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443],
    sysadmins                 => hiera('sysadmins', []),
  }
  class { 'openstack_project::static':
    project_config_repo          => 'https://git.openstack.org/openstack-infra/project-config',
    swift_authurl                => 'https://identity.api.rackspacecloud.com/v2.0/',
    swift_user                   => 'infra-files-ro',
    swift_key                    => hiera('infra_files_ro_password'),
    swift_tenant_name            => hiera('infra_files_tenant_name', 'tenantname'),
    swift_region_name            => 'DFW',
    swift_default_container      => 'infra-files',
    ssl_cert_file_contents       => hiera('static_ssl_cert_file_contents'),
    ssl_key_file_contents        => hiera('static_ssl_key_file_contents'),
    ssl_chain_file_contents      => hiera('static_ssl_chain_file_contents'),
    releases_cert_file_contents  => hiera('releases_ssl_cert_file_contents'),
    releases_key_file_contents   => hiera('releases_ssl_key_file_contents'),
    releases_chain_file_contents => hiera('releases_ssl_chain_file_contents'),
  }
}

# A machine to serve various project status updates.
# Node-OS: trusty
node 'status.openstack.org' {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443],
    sysadmins                 => hiera('sysadmins', []),
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

# Node-OS: trusty
node 'nodepool.openstack.org' {
  $group = 'nodepool'
  # TODO(pabelanger): Move all of this back into nodepool manifest, it has
  # grown too big.
  $bluebox_username    = hiera('nodepool_bluebox_username', 'username')
  $bluebox_password    = hiera('nodepool_bluebox_password')
  $bluebox_project     = hiera('nodepool_bluebox_project', 'project')
  $rackspace_username  = hiera('nodepool_rackspace_username', 'username')
  $rackspace_password  = hiera('nodepool_rackspace_password')
  $rackspace_project   = hiera('nodepool_rackspace_project', 'project')
  $hpcloud_username    = hiera('nodepool_hpcloud_username', 'username')
  $hpcloud_password    = hiera('nodepool_hpcloud_password')
  $hpcloud_project     = hiera('nodepool_hpcloud_project', 'project')
  $internap_username   = hiera('nodepool_internap_username', 'username')
  $internap_password   = hiera('nodepool_internap_password')
  $internap_project    = hiera('nodepool_internap_project', 'project')
  $ovh_username        = hiera('nodepool_ovh_username', 'username')
  $ovh_password        = hiera('nodepool_ovh_password')
  $ovh_project         = hiera('nodepool_ovh_project', 'project')
  $tripleo_username    = hiera('nodepool_tripleo_username', 'username')
  $tripleo_password    = hiera('nodepool_tripleo_password')
  $tripleo_project     = hiera('nodepool_tripleo_project', 'project')
  $infracloud_vanilla_username    = hiera('nodepool_infracloud_vanilla_username', 'username')
  $infracloud_vanilla_password    = hiera('nodepool_infracloud_vanilla_password')
  $infracloud_vanilla_project     = hiera('nodepool_infracloud_vanilla_project', 'project')
  $infracloud_chocolate_username  = hiera('nodepool_infracloud_chocolate_username', 'username')
  $infracloud_chocolate_password  = hiera('nodepool_infracloud_chocolate_password')
  $infracloud_chocolate_project   = hiera('nodepool_infracloud_chocolate_project', 'project')
  $osic_cloud1_username           = hiera('nodepool_osic_cloud1_username', 'username')
  $osic_cloud1_password           = hiera('nodepool_osic_cloud1_password')
  $osic_cloud1_project            = hiera('nodepool_osic_cloud1_project', 'project')
  $osic_cloud8_username           = hiera('nodepool_osic_cloud8_username', 'username')
  $osic_cloud8_password           = hiera('nodepool_osic_cloud8_password')
  $osic_cloud8_project            = hiera('nodepool_osic_cloud8_project', 'project')
  $vexxhost_username   = hiera('nodepool_vexxhost_username', 'username')
  $vexxhost_password   = hiera('nodepool_vexxhost_password')
  $vexxhost_project    = hiera('nodepool_vexxhost_project', 'project')
  $datacentred_username   = hiera('nodepool_datacentred_username', 'username')
  $datacentred_password   = hiera('nodepool_datacentred_password')
  $datacentred_project    = hiera('nodepool_datacentred_project', 'project')
  $citycloud_username = hiera('nodepool_citycloud_username', 'username')
  $citycloud_password = hiera('nodepool_citycloud_password')
  $entercloud_username = hiera('nodepool_entercloud_username', 'username')
  $entercloud_password = hiera('nodepool_entercloud_password')
  $clouds_yaml = template("openstack_project/nodepool/clouds.yaml.erb")

  $zk_receivers = ['nb01.openstack.org', 'nb02.openstack.org']
  $zk_iptables_rule = regsubst($zk_receivers,
                               '^(.*)$', '-m state --state NEW -m tcp -p tcp --dport 2181 -s \1 -j ACCEPT')
  $iptables_rule = flatten([$zk_iptables_rule])
  class { 'openstack_project::server':
    iptables_rules6           => $iptables_rule,
    iptables_rules4           => $iptables_rule,
    sysadmins                 => hiera('sysadmins', []),
    iptables_public_tcp_ports => [80],
  }

  class { '::zookeeper': }

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
  file { '/home/nodepool/.config/openstack/infracloud_vanilla_cacert.pem':
    ensure  => present,
    owner   => 'nodepool',
    group   => 'nodepool',
    mode    => '0600',
    content => hiera('infracloud_vanilla_ssl_cert_file_contents'),
    require => Class['::openstackci::nodepool'],
  }
  file { '/home/nodepool/.config/openstack/infracloud_chocolate_cacert.pem':
    ensure  => present,
    owner   => 'nodepool',
    group   => 'nodepool',
    mode    => '0600',
    content => hiera('infracloud_chocolate_ssl_cert_file_contents'),
    require => Class['::openstackci::nodepool'],
  }

  cron { 'mirror_gitgc':
    user        => 'nodepool',
    hour        => '20',
    minute      => '0',
    command     => 'find /opt/dib_cache/source-repositories/ -type d -name "*.git" -exec git --git-dir="{}" gc \; >/dev/null',
    environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
    require     => Class['::openstackci::nodepool'],
  }
}

# Node-OS: trusty
# Node-OS: xenial
node /^nb\d+\.openstack\.org$/ {
  $group = 'nodepool'
  # TODO(pabelanger): Move all of this back into nodepool manifest, it has
  # grown too big.
  $bluebox_username    = hiera('nodepool_bluebox_username', 'username')
  $bluebox_password    = hiera('nodepool_bluebox_password')
  $bluebox_project     = hiera('nodepool_bluebox_project', 'project')
  $rackspace_username  = hiera('nodepool_rackspace_username', 'username')
  $rackspace_password  = hiera('nodepool_rackspace_password')
  $rackspace_project   = hiera('nodepool_rackspace_project', 'project')
  $hpcloud_username    = hiera('nodepool_hpcloud_username', 'username')
  $hpcloud_password    = hiera('nodepool_hpcloud_password')
  $hpcloud_project     = hiera('nodepool_hpcloud_project', 'project')
  $internap_username   = hiera('nodepool_internap_username', 'username')
  $internap_password   = hiera('nodepool_internap_password')
  $internap_project    = hiera('nodepool_internap_project', 'project')
  $ovh_username        = hiera('nodepool_ovh_username', 'username')
  $ovh_password        = hiera('nodepool_ovh_password')
  $ovh_project         = hiera('nodepool_ovh_project', 'project')
  $tripleo_username    = hiera('nodepool_tripleo_username', 'username')
  $tripleo_password    = hiera('nodepool_tripleo_password')
  $tripleo_project     = hiera('nodepool_tripleo_project', 'project')
  $infracloud_vanilla_username    = hiera('nodepool_infracloud_vanilla_username', 'username')
  $infracloud_vanilla_password    = hiera('nodepool_infracloud_vanilla_password')
  $infracloud_vanilla_project     = hiera('nodepool_infracloud_vanilla_project', 'project')
  $infracloud_chocolate_username  = hiera('nodepool_infracloud_chocolate_username', 'username')
  $infracloud_chocolate_password  = hiera('nodepool_infracloud_chocolate_password')
  $infracloud_chocolate_project   = hiera('nodepool_infracloud_chocolate_project', 'project')
  $osic_cloud1_username           = hiera('nodepool_osic_cloud1_username', 'username')
  $osic_cloud1_password           = hiera('nodepool_osic_cloud1_password')
  $osic_cloud1_project            = hiera('nodepool_osic_cloud1_project', 'project')
  $osic_cloud8_username           = hiera('nodepool_osic_cloud8_username', 'username')
  $osic_cloud8_password           = hiera('nodepool_osic_cloud8_password')
  $osic_cloud8_project            = hiera('nodepool_osic_cloud8_project', 'project')
  $vexxhost_username   = hiera('nodepool_vexxhost_username', 'username')
  $vexxhost_password   = hiera('nodepool_vexxhost_password')
  $vexxhost_project    = hiera('nodepool_vexxhost_project', 'project')
  $datacentred_username   = hiera('nodepool_datacentred_username', 'username')
  $datacentred_password   = hiera('nodepool_datacentred_password')
  $datacentred_project    = hiera('nodepool_datacentred_project', 'project')
  $citycloud_username = hiera('nodepool_citycloud_username', 'username')
  $citycloud_password = hiera('nodepool_citycloud_password')
  $entercloud_username = hiera('nodepool_entercloud_username', 'username')
  $entercloud_password = hiera('nodepool_entercloud_password')
  $clouds_yaml = template("openstack_project/nodepool/clouds.yaml.erb")
  class { 'openstack_project::server':
    sysadmins                 => hiera('sysadmins', []),
    iptables_public_tcp_ports => [80],
  }

  include openstack_project


  class { '::openstackci::nodepool_builder':
    nodepool_ssh_public_key       => hiera('zuul_worker_ssh_public_key_contents'),
    vhost_name                    => $::fqdn,
    project_config_repo           => 'https://git.openstack.org/openstack-infra/project-config',
    oscc_file_contents            => $clouds_yaml,
    image_log_document_root       => '/var/log/nodepool/image',
    statsd_host                   => 'graphite.openstack.org',
    builder_logging_conf_template => 'openstack_project/nodepool/nodepool-builder.logging.conf.erb',
    upload_workers                => '16',
  }

  file { '/home/nodepool/.config/openstack/infracloud_vanilla_cacert.pem':
    ensure  => present,
    owner   => 'nodepool',
    group   => 'nodepool',
    mode    => '0600',
    content => hiera('infracloud_vanilla_ssl_cert_file_contents'),
    require => Class['::openstackci::nodepool_builder'],
  }
  file { '/home/nodepool/.config/openstack/infracloud_chocolate_cacert.pem':
    ensure  => present,
    owner   => 'nodepool',
    group   => 'nodepool',
    mode    => '0600',
    content => hiera('infracloud_chocolate_ssl_cert_file_contents'),
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

node 'zuulv3-dev.openstack.org' {
  $group = "zuul-merger"

  $gerrit_server        => 'review-dev.openstack.org',
  $gerrit_user          => 'zuul',
  $gerrit_ssh_host_key  => hiera('gerrit_dev_ssh_rsa_pubkey_contents'),
  $zuul_ssh_private_key => hiera('zuul_ssh_private_key_contents'),
  $zuul_url             = "http://${::fqdn}/p",
  $git_email            = 'jenkins@openstack.org',
  $git_name             = 'OpenStack Jenkins',
  $revision             = 'feature/zuulv3',

  # NOTE(pabelanger): We call ::zuul directly, so we can override all in one
  # settings.
  class { '::zuul':
    gerrit_server        => $gerrit_server,
    gerrit_user          => $gerrit_user,
    zuul_ssh_private_key => $zuul_ssh_private_key,
    git_email            => $git_email,
    git_name             => $git_name,
    revision             => $revision,
  }

  class { 'openstack_project::zuul_merger':
    gerrit_server        => $gerrit_server
    gerrit_user          => $gerrit_user,
    gerrit_ssh_host_key  => $gerrit_ssh_host_key,
    zuul_ssh_private_key => $zuul_ssh_private_key,
    revision             => $revision,
    manage_common_zuul   => false,
  }
  # TODO(pabelanger): Add zuul_scheduler support
  # TODO(pabelanger): Add zuul_launcher support
}

# Node-OS: trusty
node 'zuul.openstack.org' {
  $gearman_workers = [
    'nodepool.openstack.org',
    'zlstatic01.openstack.org',
    'zl01.openstack.org',
    'zl02.openstack.org',
    'zl03.openstack.org',
    'zl04.openstack.org',
    'zl05.openstack.org',
    'zl06.openstack.org',
    'zl07.openstack.org',
    'zm01.openstack.org',
    'zm02.openstack.org',
    'zm03.openstack.org',
    'zm04.openstack.org',
    'zm05.openstack.org',
    'zm06.openstack.org',
    'zm07.openstack.org',
    'zm08.openstack.org',
  ]
  $iptables_rules = regsubst ($gearman_workers, '^(.*)$', '-m state --state NEW -m tcp -p tcp --dport 4730 -s \1 -j ACCEPT')

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
    iptables_rules6           => $iptables_rules,
    iptables_rules4           => $iptables_rules,
    sysadmins                 => hiera('sysadmins', []),
  }

  class { 'openstack_project::zuul_prod':
    project_config_repo            => 'https://git.openstack.org/openstack-infra/project-config',
    gerrit_server                  => 'review.openstack.org',
    gerrit_user                    => 'jenkins',
    gerrit_ssh_host_key            => hiera('gerrit_ssh_rsa_pubkey_contents'),
    zuul_ssh_private_key           => hiera('zuul_ssh_private_key_contents'),
    url_pattern                    => 'http://logs.openstack.org/{build.parameters[LOG_PATH]}',
    proxy_ssl_cert_file_contents   => hiera('zuul_ssl_cert_file_contents'),
    proxy_ssl_key_file_contents    => hiera('zuul_ssl_key_file_contents'),
    proxy_ssl_chain_file_contents  => hiera('zuul_ssl_chain_file_contents'),
    zuul_url                       => 'http://zuul.openstack.org/p',
    statsd_host                    => 'graphite.openstack.org',
  }
}

# Node-OS: trusty
node /^zlstatic\d+\.openstack\.org$/ {
  $group = "zuul-merger"
  $zmq_event_receivers = ['logstash.openstack.org',
                          'nodepool.openstack.org']
  $zmq_iptables_rule = regsubst($zmq_event_receivers,
                                '^(.*)$', '-m state --state NEW -m tcp -p tcp --dport 8888 -s \1 -j ACCEPT')
  $iptables_rule = flatten([$zmq_iptables_rule])
  class { 'openstack_project::server':
    iptables_rules6     => $iptables_rule,
    iptables_rules4     => $iptables_rule,
    sysadmins           => hiera('sysadmins', []),
    puppetmaster_server => 'puppetmaster.openstack.org',
    afs                 => true,
  }
  class { 'openstack_project::zuul_launcher':
    gearman_server       => 'zuul.openstack.org',
    gerrit_server        => 'review.openstack.org',
    gerrit_user          => 'jenkins',
    gerrit_ssh_host_key  => hiera('gerrit_ssh_rsa_pubkey_contents'),
    zuul_ssh_private_key => hiera('jenkins_ssh_private_key_contents'),
    project_config_repo  => 'https://git.openstack.org/openstack-infra/project-config',
    sysadmins            => hiera('sysadmins', []),
    sites                => hiera('zuul_sites', []),
    nodes                => hiera('zuul_nodes', []),
    accept_nodes         => false,
  }
}

# Node-OS: trusty
node /^zl\d+\.openstack\.org$/ {
  $group = "zuul-merger"
  $zmq_event_receivers = ['logstash.openstack.org',
                          'nodepool.openstack.org']
  $zmq_iptables_rule = regsubst($zmq_event_receivers,
                                '^(.*)$', '-m state --state NEW -m tcp -p tcp --dport 8888 -s \1 -j ACCEPT')
  $iptables_rule = flatten([$zmq_iptables_rule])
  class { 'openstack_project::server':
    iptables_rules6     => $iptables_rule,
    iptables_rules4     => $iptables_rule,
    sysadmins           => hiera('sysadmins', []),
    puppetmaster_server => 'puppetmaster.openstack.org',
    afs                 => true,
  }
  class { 'openstack_project::zuul_launcher':
    gearman_server       => 'zuul.openstack.org',
    gerrit_server        => 'review.openstack.org',
    gerrit_user          => 'jenkins',
    gerrit_ssh_host_key  => hiera('gerrit_ssh_rsa_pubkey_contents'),
    zuul_ssh_private_key => hiera('jenkins_ssh_private_key_contents'),
    project_config_repo  => 'https://git.openstack.org/openstack-infra/project-config',
    sysadmins            => hiera('sysadmins', []),
    sites                => hiera('zuul_sites', []),
    zuul_launcher_keytab => hiera('zuul_launcher_keytab'),
  }
}

# Node-OS: trusty
node /^zm\d+\.openstack\.org$/ {
  $group = "zuul-merger"
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
    sysadmins                 => hiera('sysadmins', []),
  }

  class { 'openstack_project::zuul_merger':
    gearman_server       => 'zuul.openstack.org',
    gerrit_server        => 'review.openstack.org',
    gerrit_user          => 'jenkins',
    gerrit_ssh_host_key  => hiera('gerrit_ssh_rsa_pubkey_contents'),
    zuul_ssh_private_key => hiera('zuul_ssh_private_key_contents'),
  }
}

# Node-OS: trusty
node 'zuul-dev.openstack.org' {
  $gearman_workers = []
  $iptables_rules = regsubst ($gearman_workers, '^(.*)$', '-m state --state NEW -m tcp -p tcp --dport 4730 -s \1 -j ACCEPT')

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
    iptables_rules6           => $iptables_rules,
    iptables_rules4           => $iptables_rules,
    sysadmins                 => hiera('sysadmins', []),
  }

  class { 'openstack_project::zuul_dev':
    project_config_repo  => 'https://git.openstack.org/openstack-infra/project-config',
    gerrit_server        => 'review-dev.openstack.org',
    gerrit_user          => 'jenkins',
    gerrit_ssh_host_key  => hiera('gerrit_dev_ssh_rsa_pubkey_contents'),
    zuul_ssh_private_key => hiera('zuul_dev_ssh_private_key_contents'),
    url_pattern          => 'http://logs.openstack.org/{build.parameters[LOG_PATH]}',
    zuul_url             => 'http://zuul-dev.openstack.org/p',
    statsd_host          => 'graphite.openstack.org',
  }
}

# Node-OS: trusty
node 'pbx.openstack.org' {
  class { 'openstack_project::server':
    sysadmins                 => hiera('sysadmins', []),
    # SIP signaling is either TCP or UDP port 5060.
    # RTP media (audio/video) uses a range of UDP ports.
    iptables_public_tcp_ports => [5060],
    iptables_public_udp_ports => [5060],
    iptables_rules4           => ['-m udp -p udp --dport 10000:20000 -j ACCEPT'],
    iptables_rules6           => ['-m udp -p udp --dport 10000:20000 -j ACCEPT'],
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

# Node-OS: precise
# A backup machine.  Don't run cron or puppet agent on it.
node /^ci-backup-.*\.openstack\.org$/ {
  $group = "ci-backup"
  include openstack_project::backup_server
}

# Node-OS: trusty
node 'proposal.slave.openstack.org' {
  include openstack_project
  class { 'openstack_project::proposal_slave':
    jenkins_ssh_public_key   => $openstack_project::jenkins_ssh_key,
    proposal_ssh_public_key  => hiera('proposal_ssh_public_key_contents'),
    proposal_ssh_private_key => hiera('proposal_ssh_private_key_contents'),
    zanata_server_url        => 'https://translate.openstack.org/',
    zanata_server_user       => hiera('proposal_zanata_user'),
    zanata_server_api_key    => hiera('proposal_zanata_api_key'),
  }
}

# Node-OS: trusty
node 'release.slave.openstack.org' {
  $group = "afsadmin"

  include openstack_project
  class { 'openstack_project::release_slave':
    pypi_username          => 'openstackci',
    pypi_password          => hiera('pypi_password'),
    jenkins_ssh_public_key => $openstack_project::jenkins_ssh_key,
    jenkinsci_username     => hiera('jenkins_ci_org_user', 'username'),
    jenkinsci_password     => hiera('jenkins_ci_org_password'),
    mavencentral_username  => hiera('mavencentral_org_user', 'username'),
    mavencentral_password  => hiera('mavencentral_org_password'),
    puppet_forge_username  => hiera('puppet_forge_username', 'username'),
    puppet_forge_password  => hiera('puppet_forge_password'),
    npm_username           => 'openstackci',
    npm_userpassword       => hiera('npm_user_password'),
    npm_userurl            => 'https://openstack.org',
    admin_keytab           => hiera('afsadmin_keytab'),
    packaging_keytab       => hiera('packaging_keytab'),
  }
}

# Node-OS: trusty
node /^signing\d+\.ci\.openstack\.org$/ {
  $group = "signing"
  include openstack_project
  class { 'openstack_project::signing_node':
    jenkins_ssh_public_key => $openstack_project::jenkins_ssh_key,
    packaging_keytab       => hiera('packaging_keytab'),
    pubring                => hiera('pubring'),
    secring                => hiera('secring'),
    gerritkey              => hiera('gerritkey'),
    lp_access_token        => hiera('lp_access_token'),
    lp_access_secret       => hiera('lp_access_secret'),
    lp_consumer_key        => hiera('lp_consumer_key'),
  }
}

# Node-OS: trusty
node 'openstackid.org' {
  class { 'openstack_project::openstackid_prod':
    sysadmins                   => hiera('sysadmins', []),
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
    sysadmins                   => hiera('sysadmins', []),
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
    laravel_version             => 5,
    app_log_level               => 'debug',
    curl_verify_ssl_cert        => false,
  }
}

# Node-OS: precise
# Node-OS: trusty
# This is not meant to be an actual node that connects to the master.
# This is a dummy node definition to trigger a test of the code path used by
# nodepool's prepare_node scripts in the apply tests
# NOTE(pabelanger): These are the settings we currently use for bare-* nodes.
# It includes thick_slave.pp.
node 'single-use-slave-bare' {
  class { 'openstack_project::single_use_slave':
    # Test non-default values from prepare_node_bare.sh
    sudo => true,
    thin => false,
  }
}

# Node-OS: centos7
# Node-OS: fedora24
# Node-OS: fedora25
# Node-OS: jessie
# Node-OS: precise
# Node-OS: trusty
# Node-OS: xenial
# This is not meant to be an actual node that connects to the master.
# This is a dummy node definition to trigger a test of the code path used by
# nodepool's prepare_node scripts in the apply tests
# NOTE(pabelanger): These are the current settings we use for devstack-* nodes.
node 'single-use-slave-devstack' {
  class { 'openstack_project::single_use_slave':
    sudo => true,
    thin => true,
  }
}

# Node-OS: trusty
# Used for testing all-in-one deployments
node 'single-node-ci.test.only' {
  include ::openstackci::single_node_ci
}

# Node-OS: trusty
node 'kdc01.openstack.org' {
  class { 'openstack_project::kdc':
    sysadmins => hiera('sysadmins', []),
  }
}

# Node-OS: trusty
node 'kdc02.openstack.org' {
  class { 'openstack_project::kdc':
    sysadmins => hiera('sysadmins', []),
    slave     => true,
  }
}

# Node-OS: trusty
node 'afsdb01.openstack.org' {
  $group = "afsdb"

  class { 'openstack_project::server':
    iptables_public_udp_ports => [7000,7002,7003,7004,7005,7006,7007],
    sysadmins                 => hiera('sysadmins', []),
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
    sysadmins                 => hiera('sysadmins', []),
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
    sysadmins                 => hiera('sysadmins', []),
    afs                       => true,
    manage_exim               => true,
  }

  include openstack_project::afsfs
}

# Node-OS: trusty
node 'ask.openstack.org' {

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443],
    sysadmins                 => hiera('sysadmins', []),
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
    sysadmins                 => hiera('sysadmins', []),
  }

  class { 'openstack_project::ask_staging':
    db_password                  => hiera('ask_staging_db_password'),
    redis_password               => hiera('ask_staging_redis_password'),
  }
}

# Node-OS: trusty
node 'translate.openstack.org' {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
    sysadmins                 => hiera('sysadmins', []),
  }
  class { 'openstack_project::translate':
    admin_users             => 'aeng,camunoz,cboylan,daisyycguo,infra,jaegerandi,lyz,mordred,stevenk',
    openid_url              => 'https://openstackid.org',
    listeners               => ['ajp'],
    from_address            => 'noreply@openstack.org',
    mysql_host              => hiera('translate_mysql_host', 'localhost'),
    mysql_password          => hiera('translate_mysql_password'),
    zanata_server_user      => hiera('proposal_zanata_user'),
    zanata_server_api_key   => hiera('proposal_zanata_api_key'),
    zanata_wildfly_version  => '9.0.1',
    zanata_url              => 'https://sourceforge.net/projects/zanata/files/webapp/zanata-war-3.7.3.war',
    zanata_checksum         => '59f1ac35cce46ba4e46b06a239cd7ab4e10b5528',
    project_config_repo     => 'https://git.openstack.org/openstack-infra/project-config',
    ssl_cert_file_contents  => hiera('translate_ssl_cert_file_contents'),
    ssl_key_file_contents   => hiera('translate_ssl_key_file_contents'),
    ssl_chain_file_contents => hiera('translate_ssl_chain_file_contents'),
  }
}

# Node-OS: trusty
# Node-OS: xenial
node /^translate-dev\d*\.openstack\.org$/ {
  $group = "translate-dev"
  class { 'openstack_project::translate_dev':
    sysadmins             => hiera('sysadmins', []),
    admin_users           => 'aeng,camunoz,cboylan,daisyycguo,infra,jaegerandi,lyz,mordred,stevenk',
    openid_url            => 'https://openstackid.org',
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
node 'apps.openstack.org' {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
    sysadmins                 => hiera('sysadmins', []),
  }
  class { '::apps_site':
    ssl_cert_file           => '/etc/ssl/certs/apps.openstack.org.pem',
    ssl_cert_file_contents  => hiera('apps_ssl_cert_file_contents'),
    ssl_key_file            => '/etc/ssl/private/apps.openstack.org.key',
    ssl_key_file_contents   => hiera('apps_ssl_key_file_contents'),
    ssl_chain_file          => '/etc/ssl/certs/apps.openstack.org_intermediate.pem',
    ssl_chain_file_contents => hiera('apps_ssl_chain_file_contents'),
  }
}

# Node-OS: trusty
node 'apps-dev.openstack.org' {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
    sysadmins                 => hiera('sysadmins', []),
  }
  class { '::apps_site':
    without_glare   => false,
  }
  class { '::apps_site::plugins::glare':
    use_ssl         => false,
    memcache_server => '127.0.0.1:11211',
    vhost_name      => $::fqdn,
  }
  class { '::apps_site::wsgi::apache':
    use_ssl    => false,
    servername => $::fqdn,
  }
  class { '::apps_site::catalog':
    import_assets   => true,
    domain          => $::fqdn,
    glare_url       => "http://${::fqdn}:9494",
    memcache_server => '127.0.0.1:11211',
  }

  Class['::apps_site'] ->
    Class['::apps_site::plugins::glare'] ->
      Class['::apps_site::wsgi::apache'] ->
        Class['::apps_site::catalog']
}

# Node-OS: trusty
node 'odsreg.openstack.org' {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
    sysadmins                 => hiera('sysadmins', []),
  }
  realize (
    User::Virtual::Localuser['ttx'],
  )
  class { '::odsreg':
  }
}

# Node-OS: trusty
node 'codesearch.openstack.org' {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
    sysadmins                 => hiera('sysadmins', []),
  }
  class { 'openstack_project::codesearch':
    project_config_repo => 'https://git.openstack.org/openstack-infra/project-config',
  }
}

# Node-OS: trusty
# Node-OS: centos7
# Node-OS: xenial
node /.*wheel-mirror-.*\.openstack\.org/ {
  $group = 'wheel-mirror'
  include openstack_project

  class { 'openstack_project::wheel_mirror_slave':
    sysadmins                      => hiera('sysadmins', []),
    jenkins_ssh_public_key         => $openstack_project::jenkins_ssh_key,
    wheel_keytab                   => hiera("wheel_keytab"),
  }
}

# Node-OS: trusty
node 'controller00.vanilla.ic.openstack.org' {
  $group = 'infracloud'
  class { '::openstack_project::server':
    iptables_public_tcp_ports => [80,5000,5671,8774,9292,9696,35357], # logs,keystone,rabbit,nova,glance,neutron,keystone
    sysadmins                 => hiera('sysadmins', []),
    enable_unbound            => false,
    purge_apt_sources         => false,
  }
  class { '::openstack_project::infracloud::controller':
    keystone_rabbit_password         => hiera('keystone_rabbit_password'),
    neutron_rabbit_password          => hiera('neutron_rabbit_password'),
    nova_rabbit_password             => hiera('nova_rabbit_password'),
    root_mysql_password              => hiera('infracloud_mysql_password'),
    keystone_mysql_password          => hiera('keystone_mysql_password'),
    glance_mysql_password            => hiera('glance_mysql_password'),
    neutron_mysql_password           => hiera('neutron_mysql_password'),
    nova_mysql_password              => hiera('nova_mysql_password'),
    keystone_admin_password          => hiera('keystone_admin_password'),
    glance_admin_password            => hiera('glance_admin_password'),
    neutron_admin_password           => hiera('neutron_admin_password'),
    nova_admin_password              => hiera('nova_admin_password'),
    keystone_admin_token             => hiera('keystone_admin_token'),
    ssl_key_file_contents            => hiera('ssl_key_file_contents'),
    ssl_cert_file_contents           => hiera('infracloud_vanilla_ssl_cert_file_contents'),
    br_name                          => hiera('bridge_name'),
    controller_public_address        => $::fqdn,
    neutron_subnet_cidr              => '15.184.64.0/19',
    neutron_subnet_gateway           => '15.184.64.1',
    neutron_subnet_allocation_pools  => [
                                          'start=15.184.65.2,end=15.184.65.254',
                                          'start=15.184.66.2,end=15.184.66.254',
                                          'start=15.184.67.2,end=15.184.67.254'
                                        ],
    mysql_max_connections            => hiera('mysql_max_connections'),
  }
}

node /^compute\d{3}\.vanilla\.ic\.openstack\.org$/ {
  $group = 'infracloud'
  class { '::openstack_project::server':
    sysadmins                 => hiera('sysadmins', []),
    enable_unbound            => false,
    purge_apt_sources         => false,
  }
  class { '::openstack_project::infracloud::compute':
    nova_rabbit_password             => hiera('nova_rabbit_password'),
    neutron_rabbit_password          => hiera('neutron_rabbit_password'),
    neutron_admin_password           => hiera('neutron_admin_password'),
    ssl_key_file_contents            => hiera('ssl_key_file_contents'),
    ssl_cert_file_contents           => hiera('infracloud_vanilla_ssl_cert_file_contents'),
    br_name                          => hiera('bridge_name'),
    controller_public_address        => 'controller00.vanilla.ic.openstack.org',
  }
}

# Node-OS: trusty
node 'controller00.chocolate.ic.openstack.org' {
  $group = 'infracloud'
  class { '::openstack_project::server':
    iptables_public_tcp_ports => [80,5000,5671,8774,9292,9696,35357], # logs,keystone,rabbit,nova,glance,neutron,keystone
    sysadmins                 => hiera('sysadmins', []),
    enable_unbound            => false,
    purge_apt_sources         => false,
  }
  class { '::openstack_project::infracloud::controller':
    keystone_rabbit_password         => hiera('keystone_rabbit_password'),
    neutron_rabbit_password          => hiera('neutron_rabbit_password'),
    nova_rabbit_password             => hiera('nova_rabbit_password'),
    root_mysql_password              => hiera('infracloud_mysql_password'),
    keystone_mysql_password          => hiera('keystone_mysql_password'),
    glance_mysql_password            => hiera('glance_mysql_password'),
    neutron_mysql_password           => hiera('neutron_mysql_password'),
    nova_mysql_password              => hiera('nova_mysql_password'),
    keystone_admin_password          => hiera('keystone_admin_password'),
    glance_admin_password            => hiera('glance_admin_password'),
    neutron_admin_password           => hiera('neutron_admin_password'),
    nova_admin_password              => hiera('nova_admin_password'),
    keystone_admin_token             => hiera('keystone_admin_token'),
    ssl_key_file_contents            => hiera('infracloud_chocolate_ssl_key_file_contents'),
    ssl_cert_file_contents           => hiera('infracloud_chocolate_ssl_cert_file_contents'),
    br_name                          => 'br-vlan2551',
    controller_public_address        => $::fqdn,
    neutron_subnet_cidr              => '15.184.64.0/19',
    neutron_subnet_gateway           => '15.184.64.1',
    neutron_subnet_allocation_pools  => [
                                          'start=15.184.68.2,end=15.184.68.254',
                                          'start=15.184.69.2,end=15.184.69.254',
                                          'start=15.184.70.2,end=15.184.70.254'
                                        ]
  }
}

node /^compute\d{3}\.chocolate\.ic\.openstack\.org$/ {
  $group = 'infracloud'
  class { '::openstack_project::server':
    sysadmins                 => hiera('sysadmins', []),
    enable_unbound            => false,
    purge_apt_sources         => false,
  }
  class { '::openstack_project::infracloud::compute':
    nova_rabbit_password             => hiera('nova_rabbit_password'),
    neutron_rabbit_password          => hiera('neutron_rabbit_password'),
    neutron_admin_password           => hiera('neutron_admin_password'),
    ssl_key_file_contents            => hiera('infracloud_chocolate_ssl_key_file_contents'),
    ssl_cert_file_contents           => hiera('infracloud_chocolate_ssl_cert_file_contents'),
    br_name                          => 'br-vlan2551',
    controller_public_address        => 'controller00.chocolate.ic.openstack.org',
  }
}

# Node-OS: trusty
# Upgrade-Modules
node /^baremetal\d{2}\.vanilla\.ic\.openstack\.org$/ {
  $group = 'infracloud'
  class { '::openstack_project::server':
    iptables_public_udp_ports => [67,69],
    sysadmins                 => hiera('sysadmins', []),
    enable_unbound            => false,
    purge_apt_sources         => false,
  }

  class { '::openstack_project::infracloud::baremetal':
    ironic_inventory          => hiera('ironic_inventory', {}),
    ironic_db_password        => hiera('ironic_db_password'),
    mysql_password            => hiera('bifrost_mysql_password'),
    ipmi_passwords            => hiera('ipmi_passwords'),
    ssh_private_key           => hiera('bifrost_vanilla_ssh_private_key'),
    ssh_public_key            => hiera('bifrost_vanilla_ssh_public_key'),
    bridge_name               => hiera('bridge_name'),
    vlan                      => hiera('vlan'),
    gateway_ip                => hiera('gateway_ip'),
    default_network_interface => hiera('default_network_interface'),
    dhcp_pool_start           => hiera('dhcp_pool_start'),
    dhcp_pool_end             => hiera('dhcp_pool_end'),
    network_interface         => hiera('network_interface'),
    ipv4_nameserver           => hiera('ipv4_nameserver'),
    ipv4_subnet_mask          => hiera('ipv4_subnet_mask'),
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
