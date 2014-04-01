#
# Default: should at least behave like an opencontrail server
#
node default {
  include opencontrail_project::puppet_cron
  class { 'opencontrail_project::server':
    sysadmins => hiera('sysadmins'),
  }
}

#
# Long lived servers:
#
node 'review.opencontrail.org' {
  class { 'opencontrail_project::review':
    github_oauth_token                  => hiera('gerrit_github_token'),
    github_project_username             => hiera('github_project_username'),
    github_project_password             => hiera('github_project_password'),
    mysql_password                      => hiera('gerrit_mysql_password'),
    mysql_root_password                 => hiera('gerrit_mysql_root_password'),
    email_private_key                   => hiera('gerrit_email_private_key'),
    gerritbot_password                  => hiera('gerrit_gerritbot_password'),
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
    lp_sync_consumer_key                => hiera('gerrit_lp_consumer_key'),
    lp_sync_token                       => hiera('gerrit_lp_access_token'),
    lp_sync_secret                      => hiera('gerrit_lp_access_secret'),
    contactstore_appsec                 => hiera('gerrit_contactstore_appsec'),
    contactstore_pubkey                 => hiera('gerrit_contactstore_pubkey'),
    sysadmins                           => hiera('sysadmins'),
    swift_username                      => hiera('swift_store_user'),
    swift_password                      => hiera('swift_store_key'),
  }
}

node 'jenkins.opencontrail.org' {
  class { 'opencontrail_project::jenkins':
    jenkins_jobs_password   => hiera('jenkins_jobs_password'),
    jenkins_ssh_private_key => hiera('jenkins_ssh_private_key_contents'),
    ssl_cert_file_contents  => hiera('jenkins_ssl_cert_file_contents'),
    ssl_key_file_contents   => hiera('jenkins_ssl_key_file_contents'),
    ssl_chain_file_contents => hiera('jenkins_ssl_chain_file_contents'),
    sysadmins               => hiera('sysadmins'),
    zmq_event_receivers     => [ ],
#   zmq_event_receivers     => ['logstash.opencontrail.org',
#                               'nodepool.opencontrail.org',
  }
}

node 'jenkins01.opencontrail.org' {
  class { 'opencontrail_project::jenkins':
    jenkins_jobs_password   => hiera('jenkins_jobs_password'),
    jenkins_ssh_private_key => hiera('jenkins_ssh_private_key_contents'),
    ssl_cert_file_contents  => hiera('jenkins01_ssl_cert_file_contents'),
    ssl_key_file_contents   => hiera('jenkins01_ssl_key_file_contents'),
    ssl_chain_file_contents => hiera('jenkins01_ssl_chain_file_contents'),
    sysadmins               => hiera('sysadmins'),
    zmq_event_receivers     => [ ],
#   zmq_event_receivers     => ['logstash.opencontrail.org',
#                               'nodepool.opencontrail.org',
  }
}

node 'ci-puppetmaster.opencontrail.org' {
  class { 'opencontrail_project::puppetmaster':
    sysadmins => hiera('sysadmins'),
  }
}

node 'puppetdb.opencontrail.org' {
  class { 'opencontrail_project::puppetdb':
    sysadmins => hiera('sysadmins'),
  }
}

node 'puppet-dashboard.opencontrail.org' {
  class { 'opencontrail_project::dashboard':
    password        => hiera('dashboard_password'),
    mysql_password  => hiera('dashboard_mysql_password'),
    sysadmins       => hiera('sysadmins'),
  }
}

node 'zuul.opencontrail.org' {
  class { 'opencontrail_project::zuul_prod':
    gerrit_server        => 'review.opencontrail.org',
    gerrit_user          => 'zuul',
    gerrit_ssh_host_key  => hiera('gerrit_ssh_rsa_pubkey_contents'),
    zuul_ssh_private_key => hiera('zuul_ssh_private_key_contents'),
    url_pattern          => 'http://logs.opencontrail.org/{build.parameters[LOG_PATH]}',
    zuul_url             => 'http://zuul.opencontrail.org/p',
    sysadmins            => hiera('sysadmins'),
#   statsd_host          => 'graphite.opencontrail.org',
    gearman_workers      => [
#     'nodepool.opencontrail.org',
      'jenkins.opencontrail.org',
#     'jenkins01.opencontrail.org',
#     'zm01.opencontrail.org',
    ],
  }
}

node 'zm01.opencontrail.org' {
  class { 'opencontrail_project::zuul_merger':
    gearman_server       => 'zuul.opencontrail.org',
    gerrit_server        => 'review.opencontrail.org',
    gerrit_user          => 'zuul',
    gerrit_ssh_host_key  => hiera('gerrit_ssh_rsa_pubkey_contents'),
    zuul_ssh_private_key => hiera('jenkins_ssh_private_key_contents'),
    sysadmins            => hiera('sysadmins'),
  }
}

node 'nodepool.opencontrail.org' {
  class { 'opencontrail_project::nodepool':
    mysql_password           => hiera('nodepool_mysql_password'),
    mysql_root_password      => hiera('nodepool_mysql_root_password'),
    nodepool_ssh_private_key => hiera('jenkins_ssh_private_key_contents'),
    sysadmins                => hiera('sysadmins'),
    statsd_host              => 'graphite.opencontrail.org',
    jenkins_api_user         => hiera('jenkins_api_user'),
    jenkins_api_key          => hiera('jenkins_api_key'),
    jenkins_credentials_id   => hiera('jenkins_credentials_id'),
    rackspace_username       => hiera('nodepool_rackspace_username'),
    rackspace_password       => hiera('nodepool_rackspace_password'),
    rackspace_project        => hiera('nodepool_rackspace_project'),
    hpcloud_username         => hiera('nodepool_hpcloud_username'),
    hpcloud_password         => hiera('nodepool_hpcloud_password'),
    hpcloud_project          => hiera('nodepool_hpcloud_project'),
    tripleo_username         => hiera('nodepool_tripleo_username'),
    tripleo_password         => hiera('nodepool_tripleo_password'),
    tripleo_project          => hiera('nodepool_tripleo_project'),
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
