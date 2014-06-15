#
# Default: should at least behave like an openstack server
#
node default {
  include openstack_project::puppet_cron
  class { 'openstack_project::server':
    sysadmins => hiera('sysadmins', ['admins']),
  }
}

#
# Long lived servers:
#
node 'review.openstack.org' {
  class { 'openstack_project::review':
    github_oauth_token                  => hiera('gerrit_github_token', 'XXX'),
    github_project_username             => hiera('github_project_username', 'username'),
    github_project_password             => hiera('github_project_password', 'XXX'),
    mysql_host                          => hiera('gerrit_mysql_host', 'localhost'),
    mysql_password                      => hiera('gerrit_mysql_password', 'XXX'),
    email_private_key                   => hiera('gerrit_email_private_key', 'XXX'),
    gerritbot_password                  => hiera('gerrit_gerritbot_password', 'XXX'),
    gerritbot_ssh_rsa_key_contents      => hiera('gerritbot_ssh_rsa_key_contents', 'XXX'),
    gerritbot_ssh_rsa_pubkey_contents   => hiera('gerritbot_ssh_rsa_pubkey_contents', 'XXX'),
    ssl_cert_file_contents              => hiera('gerrit_ssl_cert_file_contents', 'XXX'),
    ssl_key_file_contents               => hiera('gerrit_ssl_key_file_contents', 'XXX'),
    ssl_chain_file_contents             => hiera('gerrit_ssl_chain_file_contents', 'XXX'),
    ssh_dsa_key_contents                => hiera('gerrit_ssh_dsa_key_contents', 'XXX'),
    ssh_dsa_pubkey_contents             => hiera('gerrit_ssh_dsa_pubkey_contents', 'XXX'),
    ssh_rsa_key_contents                => hiera('gerrit_ssh_rsa_key_contents', 'XXX'),
    ssh_rsa_pubkey_contents             => hiera('gerrit_ssh_rsa_pubkey_contents', 'XXX'),
    ssh_project_rsa_key_contents        => hiera('gerrit_project_ssh_rsa_key_contents', 'XXX'),
    ssh_project_rsa_pubkey_contents     => hiera('gerrit_project_ssh_rsa_pubkey_contents', 'XXX'),
    ssh_welcome_rsa_key_contents        => hiera('welcome_message_gerrit_ssh_private_key', 'XXX'),
    ssh_welcome_rsa_pubkey_contents     => hiera('welcome_message_gerrit_ssh_public_key', 'XXX'),
    ssh_replication_rsa_key_contents    => hiera('gerrit_replication_ssh_rsa_key_contents', 'XXX'),
    ssh_replication_rsa_pubkey_contents => hiera('gerrit_replication_ssh_rsa_pubkey_contents', 'XXX'),
    lp_sync_consumer_key                => hiera('gerrit_lp_consumer_key', 'XXX'),
    lp_sync_token                       => hiera('gerrit_lp_access_token', 'XXX'),
    lp_sync_secret                      => hiera('gerrit_lp_access_secret', 'XXX'),
    contactstore_appsec                 => hiera('gerrit_contactstore_appsec', 'XXX'),
    contactstore_pubkey                 => hiera('gerrit_contactstore_pubkey', 'XXX'),
    sysadmins                           => hiera('sysadmins', ['admins']),
    swift_username                      => hiera('swift_store_user', 'username'),
    swift_password                      => hiera('swift_store_key', 'XXX'),
  }
}

node 'review-dev.openstack.org' {
  class { 'openstack_project::review_dev':
    github_oauth_token              => hiera('gerrit_dev_github_token', 'XXX'),
    github_project_username         => hiera('github_dev_project_username', 'username'),
    github_project_password         => hiera('github_dev_project_password', 'XXX'),
    mysql_host                      => hiera('gerrit_dev_mysql_host', 'localhost'),
    mysql_password                  => hiera('gerrit_dev_mysql_password', 'XXX'),
    email_private_key               => hiera('gerrit_dev_email_private_key', 'XXX'),
    contactstore_appsec             => hiera('gerrit_dev_contactstore_appsec', 'XXX'),
    contactstore_pubkey             => hiera('gerrit_dev_contactstore_pubkey', 'XXX'),
    ssh_dsa_key_contents            => hiera('gerrit_dev_ssh_dsa_key_contents', 'XXX'),
    ssh_dsa_pubkey_contents         => hiera('gerrit_dev_ssh_dsa_pubkey_contents', 'XXX'),
    ssh_rsa_key_contents            => hiera('gerrit_dev_ssh_rsa_key_contents', 'XXX'),
    ssh_rsa_pubkey_contents         => hiera('gerrit_dev_ssh_rsa_pubkey_contents', 'XXX'),
    ssh_project_rsa_key_contents    => hiera('gerrit_dev_project_ssh_rsa_key_contents', 'XXX'),
    ssh_project_rsa_pubkey_contents => hiera('gerrit_dev_project_ssh_rsa_pubkey_contents', 'XXX'),
    lp_sync_consumer_key            => hiera('gerrit_dev_lp_consumer_key', 'XXX'),
    lp_sync_token                   => hiera('gerrit_dev_lp_access_token', 'XXX'),
    lp_sync_secret                  => hiera('gerrit_dev_lp_access_secret', 'XXX'),
    sysadmins                       => hiera('sysadmins', ['admins']),
  }
}

node 'jenkins.openstack.org' {
  class { 'openstack_project::jenkins':
    jenkins_jobs_password   => hiera('jenkins_jobs_password', 'XXX'),
    jenkins_ssh_private_key => hiera('jenkins_ssh_private_key_contents', 'XXX'),
    ssl_cert_file_contents  => hiera('jenkins_ssl_cert_file_contents', 'XXX'),
    ssl_key_file_contents   => hiera('jenkins_ssl_key_file_contents', 'XXX'),
    ssl_chain_file_contents => hiera('jenkins_ssl_chain_file_contents', 'XXX'),
    sysadmins               => hiera('sysadmins', ['admins']),
    zmq_event_receivers     => ['logstash.openstack.org',
                                'nodepool.openstack.org',
    ],
  }
}

node /^jenkins\d+\.openstack\.org$/ {
  class { 'openstack_project::jenkins':
    jenkins_jobs_password   => hiera('jenkins_jobs_password', 'XXX'),
    jenkins_ssh_private_key => hiera('jenkins_ssh_private_key_contents', 'XXX'),
    ssl_cert_file           => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
    ssl_key_file            => '/etc/ssl/private/ssl-cert-snakeoil.key',
    ssl_chain_file          => '',
    sysadmins               => hiera('sysadmins', ['admins']),
    zmq_event_receivers     => ['logstash.openstack.org',
                                'nodepool.openstack.org',
    ],
  }
}

node 'jenkins-dev.openstack.org' {
  class { 'openstack_project::jenkins_dev':
    jenkins_ssh_private_key  => hiera('jenkins_dev_ssh_private_key_contents', 'XXX'),
    sysadmins                => hiera('sysadmins', ['admins']),
    mysql_password           => hiera('nodepool_dev_mysql_password', 'XXX'),
    mysql_root_password      => hiera('nodepool_dev_mysql_root_password', 'XXX'),
    nodepool_ssh_private_key => hiera('jenkins_dev_ssh_private_key_contents', 'XXX'),
    jenkins_api_user         => hiera('jenkins_dev_api_user', 'username'),
    jenkins_api_key          => hiera('jenkins_dev_api_key', 'XXX'),
    jenkins_credentials_id   => hiera('jenkins_dev_credentials_id', 'XXX'),
    hpcloud_username         => hiera('nodepool_hpcloud_username', 'username'),
    hpcloud_password         => hiera('nodepool_hpcloud_password', 'XXX'),
    hpcloud_project          => hiera('nodepool_hpcloud_project', 'XXX'),
  }
}

node 'cacti.openstack.org' {
  include openstack_project::ssl_cert_check
  class { 'openstack_project::cacti':
    sysadmins => hiera('sysadmins', ['admin']),
  }
}

node 'community.openstack.org' {
  class { 'openstack_project::community':
    sysadmins => hiera('sysadmins', ['admin']),
  }
}

node 'ci-puppetmaster.openstack.org' {
  class { 'openstack_project::puppetmaster':
    root_rsa_key    => hiera('puppetmaster_root_rsa_key', 'XXX'),
    override_list   => [
      'git01.openstack.org',
      'git02.openstack.org',
      'git03.openstack.org',
      'git04.openstack.org',
      'git05.openstack.org',
      'review.openstack.org',
    ],
    sysadmins       => hiera('sysadmins', ['admin']),
  }
}

node 'puppetdb.openstack.org' {
  class { 'openstack_project::puppetdb':
    sysadmins => hiera('sysadmins', ['admin']),
  }
}

node 'graphite.openstack.org' {
  class { 'openstack_project::graphite':
    sysadmins               => hiera('sysadmins', ['admin']),
    graphite_admin_user     => hiera('graphite_admin_user', 'username'),
    graphite_admin_email    => hiera('graphite_admin_email', 'email@example.com'),
    graphite_admin_password => hiera('graphite_admin_password', 'XXX'),
    statsd_hosts            => ['logstash.openstack.org',
                                'nodepool.openstack.org',
                                'zuul.openstack.org'],
  }
}

node 'groups.openstack.org' {
  class { 'openstack_project::groups':
    sysadmins => hiera('sysadmins', ['admin']),
  }
}

node 'groups-dev.openstack.org' {
  class { 'openstack_project::groups_dev':
    sysadmins           => hiera('sysadmins', ['admin']),
    site_admin_password => hiera('groups_dev_site_admin_password', 'XXX'),
    site_mysql_host     => hiera('groups_dev_site_mysql_host', 'localhost'),
    site_mysql_password => hiera('groups_dev_site_mysql_password', 'XXX'),
  }
}

node 'lists.openstack.org' {
  class { 'openstack_project::lists':
    listadmins   => hiera('listadmins', ['admin']),
    listpassword => hiera('listpassword', 'XXX'),
  }
}

node 'paste.openstack.org' {
  class { 'openstack_project::paste':
    db_host     => hiera('paste_db_host', 'localhost'),
    db_password => hiera('paste_db_password', 'XXX'),
    sysadmins   => hiera('sysadmins', ['admin']),
  }
}

node 'planet.openstack.org' {
  class { 'openstack_project::planet':
    sysadmins => hiera('sysadmins', ['admin']),
  }
}

node 'eavesdrop.openstack.org' {
  class { 'openstack_project::eavesdrop':
    nickpass                => hiera('openstack_meetbot_password', 'XXX'),
    sysadmins               => hiera('sysadmins', ['admin']),
    statusbot_nick          => hiera('statusbot_nick', 'username'),
    statusbot_password      => hiera('statusbot_nick_password', 'XXX'),
    statusbot_server        => 'chat.freenode.net',
    statusbot_channels      => 'edeploy, fuel-dev, heat, magnetodb, murano, openstack, openstack-101, openstack-anvil, openstack-bacon, openstack-barbican, openstack-blazar, openstack-board, openstack-ceilometer, openstack-chef, openstack-cinder, openstack-climate, openstack-cloudkeep, openstack-community, openstack-containers, openstack-dev, openstack-dns, openstack-doc, openstack-entropy, openstack-foundation, openstack-gantt, openstack-gate, openstack-hyper-v, openstack-infra, openstack-ironic, openstack-keystone, openstack-manila, openstack-marconi, openstack-meeting, openstack-meeting-3, openstack-meeting-alt, openstack-meniscus, openstack-merges, openstack-metering, openstack-neutron, openstack-nova, openstack-opw, openstack-oslo, openstack-packaging, openstack-qa, openstack-raksha, openstack-relmgr-office, openstack-sahara, openstack-sdks, openstack-state-management, openstack-swift, openstack-translation, openstack-trove, packstack-dev, refstack, storyboard, syscompass, tripleo',
    statusbot_auth_nicks    => 'jeblair, ttx, fungi, mordred, clarkb, sdague, SergeyLukjanov, jhesketh, lifeless',
    statusbot_wiki_user     => hiera('statusbot_wiki_username', 'username'),
    statusbot_wiki_password => hiera('statusbot_wiki_password', 'XXX'),
    statusbot_wiki_url      => 'https://wiki.openstack.org/w/api.php',
    statusbot_wiki_pageid   => '1781',
    accessbot_nick          => hiera('accessbot_nick', 'username'),
    accessbot_password      => hiera('accessbot_nick_password', 'XXX'),
  }
}

node 'etherpad.openstack.org' {
  class { 'openstack_project::etherpad':
    ssl_cert_file_contents  => hiera('etherpad_ssl_cert_file_contents', 'XXX'),
    ssl_key_file_contents   => hiera('etherpad_ssl_key_file_contents', 'XXX'),
    ssl_chain_file_contents => hiera('etherpad_ssl_chain_file_contents', 'XXX'),
    mysql_host              => hiera('etherpad_db_host', 'localhost'),
    mysql_user              => hiera('etherpad_db_user', 'username'),
    mysql_password          => hiera('etherpad_db_password', 'XXX'),
    sysadmins               => hiera('sysadmins', ['admin']),
  }
}

node 'etherpad-dev.openstack.org' {
  class { 'openstack_project::etherpad_dev':
    mysql_host          => hiera('etherpad-dev_db_host', 'localhost'),
    mysql_user          => hiera('etherpad-dev_db_user', 'username'),
    mysql_password      => hiera('etherpad-dev_db_password', 'XXX'),
    sysadmins           => hiera('sysadmins', ['admin']),
  }
}

node 'wiki.openstack.org' {
  class { 'openstack_project::wiki':
    mysql_root_password     => hiera('wiki_db_password', 'XXX'),
    sysadmins               => hiera('sysadmins', ['admin']),
    ssl_cert_file_contents  => hiera('wiki_ssl_cert_file_contents', 'XXX'),
    ssl_key_file_contents   => hiera('wiki_ssl_key_file_contents', 'XXX'),
    ssl_chain_file_contents => hiera('wiki_ssl_chain_file_contents', 'XXX'),
  }
}

$elasticsearch_nodes = [
  'elasticsearch01.openstack.org',
  'elasticsearch02.openstack.org',
  'elasticsearch03.openstack.org',
  'elasticsearch04.openstack.org',
  'elasticsearch05.openstack.org',
  'elasticsearch06.openstack.org',
  'elasticsearch07.openstack.org',
]

node 'logstash.openstack.org' {
  class { 'openstack_project::logstash':
    sysadmins                       => hiera('sysadmins', ['admin']),
    elasticsearch_nodes             => $elasticsearch_nodes,
    gearman_workers                 => [
      'logstash-worker01.openstack.org',
      'logstash-worker02.openstack.org',
      'logstash-worker03.openstack.org',
      'logstash-worker04.openstack.org',
      'logstash-worker05.openstack.org',
      'logstash-worker06.openstack.org',
      'logstash-worker07.openstack.org',
      'logstash-worker08.openstack.org',
      'logstash-worker09.openstack.org',
      'logstash-worker10.openstack.org',
      'logstash-worker11.openstack.org',
      'logstash-worker12.openstack.org',
      'logstash-worker13.openstack.org',
      'logstash-worker14.openstack.org',
      'logstash-worker15.openstack.org',
      'logstash-worker16.openstack.org',
      'logstash-worker17.openstack.org',
      'logstash-worker18.openstack.org',
      'logstash-worker19.openstack.org',
      'logstash-worker20.openstack.org',
    ],
    discover_nodes                  => [
      'elasticsearch02.openstack.org:9200',
      'elasticsearch03.openstack.org:9200',
      'elasticsearch04.openstack.org:9200',
      'elasticsearch05.openstack.org:9200',
      'elasticsearch06.openstack.org:9200',
      'elasticsearch07.openstack.org:9200',
    ],
  }
}

node /^logstash-worker\d+\.openstack\.org$/ {
  class { 'openstack_project::logstash_worker':
    sysadmins           => hiera('sysadmins', ['admin']),
    elasticsearch_nodes => $elasticsearch_nodes,
    discover_node       => 'elasticsearch02.openstack.org',
  }
}

node /^elasticsearch0[1-7]\.openstack\.org$/ {
  class { 'openstack_project::elasticsearch_node':
    sysadmins             => hiera('sysadmins', ['admin']),
    elasticsearch_nodes   => $elasticsearch_nodes,
    elasticsearch_clients => [
      'logstash.openstack.org',
      'logstash-worker01.openstack.org',
      'logstash-worker02.openstack.org',
      'logstash-worker03.openstack.org',
      'logstash-worker04.openstack.org',
      'logstash-worker05.openstack.org',
      'logstash-worker06.openstack.org',
      'logstash-worker07.openstack.org',
      'logstash-worker08.openstack.org',
      'logstash-worker09.openstack.org',
      'logstash-worker10.openstack.org',
      'logstash-worker11.openstack.org',
      'logstash-worker12.openstack.org',
      'logstash-worker13.openstack.org',
      'logstash-worker14.openstack.org',
      'logstash-worker15.openstack.org',
      'logstash-worker16.openstack.org',
      'logstash-worker17.openstack.org',
      'logstash-worker18.openstack.org',
      'logstash-worker19.openstack.org',
      'logstash-worker20.openstack.org',
    ],
    discover_nodes        => $elasticsearch_nodes,
  }
}

# A CentOS machine to load balance git access.
node 'git.openstack.org' {
  class { 'openstack_project::git':
    sysadmins               => hiera('sysadmins', ['admin']),
    balancer_member_names   => [
      'git01.openstack.org',
      'git02.openstack.org',
      'git03.openstack.org',
      'git04.openstack.org',
      'git05.openstack.org',
    ],
    balancer_member_ips     => [
      '198.61.223.164',
      '23.253.102.209',
      '162.242.144.38',
      '166.78.46.164',
      '166.78.46.121',
    ],
  }
}

# CentOS machines to run cgit and git daemon. Will be
# load balanced by git.openstack.org.
node /^git\d+\.openstack\.org$/ {
  include openstack_project
  class { 'openstack_project::git_backend':
    vhost_name              => 'git.openstack.org',
    sysadmins               => hiera('sysadmins', ['admin']),
    git_gerrit_ssh_key      => hiera('gerrit_replication_ssh_rsa_pubkey_contents', 'XXX'),
    ssl_cert_file_contents  => hiera('git_ssl_cert_file_contents', 'XXX'),
    ssl_key_file_contents   => hiera('git_ssl_key_file_contents', 'XXX'),
    ssl_chain_file_contents => hiera('git_ssl_chain_file_contents', 'XXX'),
    behind_proxy            => true,
  }
}

# A machine to run ODSREG in preparation for summits.
node 'summit.openstack.org' {
  class { 'openstack_project::summit':
    sysadmins => hiera('sysadmins', ['admin']),
  }
}

# A machine to run Storyboard
node 'storyboard.openstack.org' {
  class { 'openstack_project::storyboard':
    sysadmins               => hiera('sysadmins', ['admin']),
    mysql_host              => hiera('storyboard_db_host', 'localhost'),
    mysql_user              => hiera('storyboard_db_user', 'username'),
    mysql_password          => hiera('storyboard_db_password', 'XXX'),
    ssl_cert_file_contents  => hiera('storyboard_ssl_cert_file_contents', 'XXX'),
    ssl_key_file_contents   => hiera('storyboard_ssl_key_file_contents', 'XXX'),
    ssl_chain_file_contents => hiera('storyboard_ssl_chain_file_contents', 'XXX'),
  }
}

# A machine to serve static content.
node 'static.openstack.org' {
  class { 'openstack_project::static':
    sysadmins => hiera('sysadmins', ['admin']),
  }
}

# A machine to serve various project status updates.
node 'status.openstack.org' {
  class { 'openstack_project::status':
    sysadmins                     => hiera('sysadmins', ['admin']),
    gerrit_host                   => 'review.openstack.org',
    gerrit_ssh_host_key           => hiera('gerrit_ssh_rsa_pubkey_contents', 'XXX'),
    reviewday_ssh_public_key      => hiera('reviewday_rsa_pubkey_contents', 'XXX'),
    reviewday_ssh_private_key     => hiera('reviewday_rsa_key_contents', 'XXX'),
    releasestatus_ssh_public_key  => hiera('releasestatus_rsa_pubkey_contents', 'XXX'),
    releasestatus_ssh_private_key => hiera('releasestatus_rsa_key_contents', 'XXX'),
    recheck_ssh_public_key        => hiera('elastic-recheck_gerrit_ssh_public_key', 'XXX'),
    recheck_ssh_private_key       => hiera('elastic-recheck_gerrit_ssh_private_key', 'XXX'),
    recheck_bot_nick              => 'openstackrecheck',
    recheck_bot_passwd            => hiera('elastic-recheck_ircbot_password', 'XXX'),
  }
}

node 'nodepool.openstack.org' {
  class { 'openstack_project::nodepool_prod':
    mysql_password           => hiera('nodepool_mysql_password', 'XXX'),
    mysql_root_password      => hiera('nodepool_mysql_root_password', 'XXX'),
    nodepool_ssh_private_key => hiera('jenkins_ssh_private_key_contents', 'XXX'),
    sysadmins                => hiera('sysadmins', ['admin']),
    statsd_host              => 'graphite.openstack.org',
    jenkins_api_user         => hiera('jenkins_api_user', 'username'),
    jenkins_api_key          => hiera('jenkins_api_key', 'XXX'),
    jenkins_credentials_id   => hiera('jenkins_credentials_id', 'XXX'),
    rackspace_username       => hiera('nodepool_rackspace_username', 'username'),
    rackspace_password       => hiera('nodepool_rackspace_password', 'XXX'),
    rackspace_project        => hiera('nodepool_rackspace_project', 'project'),
    hpcloud_username         => hiera('nodepool_hpcloud_username', 'username'),
    hpcloud_password         => hiera('nodepool_hpcloud_password', 'XXX'),
    hpcloud_project          => hiera('nodepool_hpcloud_project', 'project'),
    tripleo_username         => hiera('nodepool_tripleo_username', 'username'),
    tripleo_password         => hiera('nodepool_tripleo_password', 'XXX'),
    tripleo_project          => hiera('nodepool_tripleo_project', 'project'),
  }
}

node 'zuul.openstack.org' {
  class { 'openstack_project::zuul_prod':
    gerrit_server                  => 'review.openstack.org',
    gerrit_user                    => 'jenkins',
    gerrit_ssh_host_key            => hiera('gerrit_ssh_rsa_pubkey_contents', 'XXX'),
    zuul_ssh_private_key           => hiera('zuul_ssh_private_key_contents', 'XXX'),
    url_pattern                    => 'http://logs.openstack.org/{build.parameters[LOG_PATH]}',
    swift_authurl                  => 'https://identity.api.rackspacecloud.com/v2.0/',
    swift_user                     => 'infra-files-rw',
    swift_key                      => hiera('infra_files_rw_password', 'XXX'),
    swift_tenant_name              => hiera('infra_files_tenant_name', 'tenantname'),
    swift_region_name              => 'DFW',
    swift_default_container        => 'infra-files',
    swift_default_logserver_prefix => 'http://logs.openstack.org/',
    zuul_url                       => 'http://zuul.openstack.org/p',
    sysadmins                      => hiera('sysadmins', ['admin']),
    statsd_host                    => 'graphite.openstack.org',
    gearman_workers                => [
      'nodepool.openstack.org',
      'jenkins.openstack.org',
      'jenkins01.openstack.org',
      'jenkins02.openstack.org',
      'jenkins03.openstack.org',
      'jenkins04.openstack.org',
      'jenkins05.openstack.org',
      'jenkins06.openstack.org',
      'jenkins07.openstack.org',
      'jenkins-dev.openstack.org',
      'zm01.openstack.org',
      'zm02.openstack.org',
    ],
  }
}

node 'zm01.openstack.org' {
  class { 'openstack_project::zuul_merger':
    gearman_server       => 'zuul.openstack.org',
    gerrit_server        => 'review.openstack.org',
    gerrit_user          => 'jenkins',
    gerrit_ssh_host_key  => hiera('gerrit_ssh_rsa_pubkey_contents', 'XXX'),
    zuul_ssh_private_key => hiera('zuul_ssh_private_key_contents', 'XXX'),
    sysadmins            => hiera('sysadmins', ['admin']),
  }
}

node 'zm02.openstack.org' {
  class { 'openstack_project::zuul_merger':
    gearman_server       => 'zuul.openstack.org',
    gerrit_server        => 'review.openstack.org',
    gerrit_user          => 'jenkins',
    gerrit_ssh_host_key  => hiera('gerrit_ssh_rsa_pubkey_contents', 'XXX'),
    zuul_ssh_private_key => hiera('zuul_ssh_private_key_contents', 'XXX'),
    sysadmins            => hiera('sysadmins', ['admin']),
  }
}

node 'zuul-dev.openstack.org' {
  class { 'openstack_project::zuul_dev':
    gerrit_server        => 'review-dev.openstack.org',
    gerrit_user          => 'zuul-dev',
    zuul_ssh_private_key => hiera('zuul_dev_ssh_private_key_contents', 'XXX'),
    url_pattern          => 'http://logs.openstack.org/{build.parameters[LOG_PATH]}',
    zuul_url             => 'http://zuul-dev.openstack.org/p',
    sysadmins            => hiera('sysadmins', ['admin']),
    statsd_host          => 'graphite.openstack.org',
    gearman_workers      => [
      'jenkins.openstack.org',
      'jenkins01.openstack.org',
      'jenkins02.openstack.org',
      'jenkins03.openstack.org',
      'jenkins04.openstack.org',
      'jenkins05.openstack.org',
      'jenkins06.openstack.org',
      'jenkins07.openstack.org',
      'jenkins-dev.openstack.org',
    ],
  }
}

node 'pbx.openstack.org' {
  class { 'openstack_project::pbx':
    sysadmins     => hiera('sysadmins', ['admin']),
    sip_providers => [
      {
        provider => 'voipms',
        hostname => 'dallas.voip.ms',
        username => hiera('voipms_username', 'username'),
        password => hiera('voipms_password', 'XXX'),
        outgoing => false,
      },
    ],
  }
}

# A backup machine.  Don't run cron or puppet agent on it.
node /^ci-backup-.*\.openstack\.org$/ {
  include openstack_project::backup_server
}

#
# Jenkins slaves:
#

node 'mirror26.slave.openstack.org' {
  include openstack_project
  class { 'openstack_project::mirror26_slave':
    jenkins_ssh_public_key  => $openstack_project::jenkins_ssh_key,
    jenkins_ssh_private_key => hiera('jenkins_ssh_private_key_contents', 'XXX')
  }
}

node 'mirror27.slave.openstack.org' {
  include openstack_project
  class { 'openstack_project::mirror27_slave':
    jenkins_ssh_public_key  => $openstack_project::jenkins_ssh_key,
    jenkins_ssh_private_key => hiera('jenkins_ssh_private_key_contents', 'XXX')
  }
}

node 'mirror33.slave.openstack.org' {
  include openstack_project
  class { 'openstack_project::mirror33_slave':
    jenkins_ssh_public_key  => $openstack_project::jenkins_ssh_key,
    jenkins_ssh_private_key => hiera('jenkins_ssh_private_key_contents', 'XXX')
  }
}

node 'proposal.slave.openstack.org' {
  include openstack_project
  class { 'openstack_project::proposal_slave':
    transifex_username       => 'openstackjenkins',
    transifex_password       => hiera('transifex_password', 'XXX'),
    jenkins_ssh_public_key   => $openstack_project::jenkins_ssh_key,
    proposal_ssh_public_key  => hiera('proposal_ssh_public_key_contents', 'XXX'),
    proposal_ssh_private_key => hiera('proposal_ssh_private_key_contents', 'XXX'),
  }
}

node 'pypi.slave.openstack.org' {
  include openstack_project
  class { 'openstack_project::pypi_slave':
    pypi_username          => 'openstackci',
    pypi_password          => hiera('pypi_password', 'XXX'),
    jenkins_ssh_public_key => $openstack_project::jenkins_ssh_key,
    jenkinsci_username     => hiera('jenkins_ci_org_user', 'username'),
    jenkinsci_password     => hiera('jenkins_ci_org_password', 'XXX'),
    mavencentral_username  => hiera('mavencentral_org_user', 'username'),
    mavencentral_password  => hiera('mavencentral_org_password', 'XXX'),
  }
}

node 'salt-trigger.slave.openstack.org' {
  include openstack_project
  class { 'openstack_project::salt_trigger_slave':
    jenkins_ssh_public_key => $openstack_project::jenkins_ssh_key,
  }
}

node /^precise-dev\d+.*\.slave\.openstack\.org$/ {
  include openstack_project
  include openstack_project::puppet_cron
  class { 'openstack_project::slave':
    ssh_key   => $openstack_project::jenkins_dev_ssh_key,
    sysadmins => hiera('sysadmins', ['admin']),
  }
}

node /^precisepy3k-dev\d+.*\.slave\.openstack\.org$/ {
  include openstack_project
  include openstack_project::puppet_cron
  class { 'openstack_project::slave':
    ssh_key      => $openstack_project::jenkins_dev_ssh_key,
    sysadmins    => hiera('sysadmins', ['admin']),
    python3      => true,
    include_pypy => true,
  }
}

node /^centos6-dev\d+\.slave\.openstack\.org$/ {
  include openstack_project
  include openstack_project::puppet_cron
  class { 'openstack_project::slave':
    ssh_key   => $openstack_project::jenkins_dev_ssh_key,
    sysadmins => hiera('sysadmins', ['admin']),
  }
}

node /^fedora18-dev\d+\.slave\.openstack\.org$/ {
  include openstack_project
  include openstack_project::puppet_cron
  class { 'openstack_project::slave':
    ssh_key   => $openstack_project::jenkins_dev_ssh_key,
    sysadmins => hiera('sysadmins', ['admin']),
    python3   => true,
  }
}

node 'openstackid-dev.openstack.org' {
  class { 'openstack_project::openstackid_dev':
    sysadmins               => hiera('sysadmins', ['admin']),
    site_admin_password     => hiera('openstackid_dev_site_admin_password', 'XXX'),
    id_mysql_host           => hiera('openstackid_dev_id_mysql_host', 'localhost'),
    id_mysql_password       => hiera('openstackid_dev_id_mysql_password', 'XXX'),
    ss_mysql_host           => hiera('openstackid_dev_ss_mysql_host', 'localhost'),
    ss_mysql_password       => hiera('openstackid_dev_ss_mysql_password', 'XXX'),
    ss_mysql_user           => hiera('openstackid_dev_ss_mysql_user', 'username'),
    ss_db_name              => hiera('openstackid_dev_ss_db_name', 'username'),
    redis_password          => hiera('openstackid_dev_redis_password', 'XXX'),
    ssl_cert_file_contents  => hiera('openstackid_dev_ssl_cert_file_contents', 'XXX'),
    ssl_key_file_contents   => hiera('openstackid_dev_ssl_key_file_contents', 'XXX'),
    ssl_chain_file_contents => hiera('openstackid_dev_ssl_chain_file_contents', 'XXX'),
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
