#
# Default: should at least behave like an openstack server
#
node default {
  include openstack_project::puppet_cron
  class { 'openstack_project::server':
    sysadmins => hiera('sysadmins'),
  }
}

#
# Long lived servers:
#
node 'review.openstack.org' {
  class { 'openstack_project::review':
    github_oauth_token      => hiera('gerrit_github_token'),
    mysql_password          => hiera('gerrit_mysql_password'),
    mysql_root_password     => hiera('gerrit_mysql_root_password'),
    email_private_key       => hiera('gerrit_email_private_key'),
    gerritbot_password      => hiera('gerrit_gerritbot_password'),
    ssl_cert_file_contents  => hiera('gerrit_ssl_cert_file_contents'),
    ssl_key_file_contents   => hiera('gerrit_ssl_key_file_contents'),
    ssl_chain_file_contents => hiera('gerrit_ssl_chain_file_contents'),
    sysadmins               => hiera('sysadmins'),
  }
}

node 'gerrit-dev.openstack.org', 'review-dev.openstack.org' {
  class { 'openstack_project::review_dev':
    github_oauth_token  => hiera('gerrit_dev_github_token'),
    mysql_password      => hiera('gerrit_dev_mysql_password'),
    mysql_root_password => hiera('gerrit_dev_mysql_root_password'),
    email_private_key   => hiera('gerrit_dev_email_private_key'),
    contactstore_appsec => hiera('gerrit_dev_contactstore_appsec'),
    contactstore_pubkey => hiera('gerrit_dev_contactstore_pubkey'),
    lp_sync_key         => hiera('gerrit_dev_lp_sync_key'),
    lp_sync_pubkey      => hiera('gerrit_dev_lp_sync_pubkey'),
    lp_sync_token       => hiera('gerrit_dev_lp_access_token'),
    lp_sync_secret      => hiera('gerrit_dev_lp_access_secret'),
    sysadmins           => hiera('sysadmins'),
  }
}

node 'review-dev2.openstack.org' {
  class { 'openstack_project::review_dev':
    github_oauth_token  => hiera('gerrit_dev_github_token'),
    mysql_password      => hiera('gerrit_dev_mysql_password'),
    mysql_root_password => hiera('gerrit_dev_mysql_root_password'),
    email_private_key   => hiera('gerrit_dev_email_private_key'),
    contactstore_appsec => hiera('gerrit_dev_contactstore_appsec'),
    contactstore_pubkey => hiera('gerrit_dev_contactstore_pubkey'),
    lp_sync_key         => hiera('gerrit_dev_lp_sync_key'),
    lp_sync_pubkey      => hiera('gerrit_dev_lp_sync_pubkey'),
    lp_sync_token       => hiera('gerrit_dev_lp_access_token'),
    lp_sync_secret      => hiera('gerrit_dev_lp_access_secret'),
    replicate_github    => false,
    sysadmins           => hiera('sysadmins'),
  }
}

node 'jenkins.openstack.org' {
  class { 'openstack_project::jenkins':
    jenkins_jobs_password   => hiera('jenkins_jobs_password'),
    ssl_cert_file_contents  => hiera('jenkins_ssl_cert_file_contents'),
    ssl_key_file_contents   => hiera('jenkins_ssl_key_file_contents'),
    ssl_chain_file_contents => hiera('jenkins_ssl_chain_file_contents'),
    sysadmins               => hiera('sysadmins'),
  }
  class { 'openstack_project::zuul':
    jenkins_server  => "https://${::fqdn}",
    jenkins_user    => 'hudson-openstack',
    jenkins_apikey  => hiera('zuul_jenkins_apikey'),
    gerrit_server   => 'review.openstack.org',
    gerrit_user     => 'jenkins',
    url_pattern     => 'http://logs.openstack.org/{change.number}/{change.patchset}/{pipeline.name}/{job.name}/{build.number}',
  }
}

node 'jenkins-dev.openstack.org' {
  class { 'openstack_project::jenkins_dev':
    sysadmins => hiera('sysadmins'),
  }
}

node 'community.openstack.org' {
  class { 'openstack_project::community':
    sysadmins => hiera('sysadmins'),
  }
}

node 'ci-puppetmaster.openstack.org' {
  class { 'openstack_project::puppetmaster':
    sysadmins => hiera('sysadmins'),
  }
}

node 'lists.openstack.org' {
  class { 'openstack_project::lists':
    listadmins => hiera('listadmins'),
  }
}

node 'paste.openstack.org' {
  class { 'openstack_project::paste':
    sysadmins => hiera('sysadmins'),
  }
}

node 'planet.openstack.org' {
  class { 'openstack_project::planet':
    sysadmins => hiera('sysadmins'),
  }
}

node 'eavesdrop.openstack.org' {
  class { 'openstack_project::eavesdrop':
    nickpass  => hiera('openstack_meetbot_password'),
    sysadmins => hiera('sysadmins'),
  }
}

node 'pypi.openstack.org' {
  class { 'openstack_project::pypi':
    sysadmins => hiera('sysadmins'),
  }
}

node 'etherpad.openstack.org' {
  class { 'openstack_project::etherpad':
    etherpad_crt      => hiera('etherpad_crt'),
    etherpad_key      => hiera('etherpad_key'),
    database_password => hiera('etherpad_db_password'),
    sysadmins         => hiera('sysadmins'),
  }
}

node 'wiki.openstack.org' {
  class { 'openstack_project::wiki':
    mysql_root_password => hiera('wiki_db_password'),
    sysadmins           => hiera('sysadmins'),
  }
}

node 'puppet-dashboard.openstack.org' {
  class { 'openstack_project::dashboard':
    password        => hiera('dashboard_password'),
    mysql_password  => hiera('dashboard_mysql_password'),
    sysadmins       => hiera('sysadmins'),
  }
}

# A machine to serve static content.
node 'static.openstack.org' {
  class { 'openstack_project::static':
    sysadmins => hiera('sysadmins'),
  }
}

# A bare machine, but with a jenkins user
node /^.*\.template\.openstack\.org$/ {
  include openstack_project::slave_template
}

# A backup machine.  Don't run cron or puppet agent on it.
node /^ci-backup-.*\.openstack\.org$/ {
  include openstack_project::backup_server
}

#
# Jenkins slaves:
#

node 'tx.slave.openstack.org' {
  class { 'openstack_project::translation_slave':
    transifex_username => 'openstackjenkins',
    transifex_password => hiera('transifex_password')
  }
}

# Rollout cgroups to precise slaves.
node /^precise.*\.slave\.openstack\.org$/ {
  include jenkins::cgroups
  include openstack_project::puppet_cron
  include ulimit
  class { 'openstack_project::slave':
    certname  => 'precise.slave.openstack.org',
    sysadmins => hiera('sysadmins'),
  }
  class { 'openstack_project::glancetest':
    s3_store_access_key   => hiera('s3_store_access_key'),
    s3_store_secret_key   => hiera('s3_store_secret_key'),
    s3_store_bucket       => hiera('s3_store_bucket'),
    swift_store_user      => hiera('swift_store_user'),
    swift_store_key       => hiera('swift_store_key'),
    swift_store_container => hiera('swift_store_container'),
  }
  ulimit::conf { 'limit_jenkins_procs':
    limit_domain => 'jenkins',
    limit_type   => 'hard',
    limit_item   => 'nproc',
    limit_value  => '256'
  }
}

node /^oneiric.*\.slave\.openstack\.org$/ {
  include openstack_project::puppet_cron
  class { 'openstack_project::slave':
    certname  => 'oneiric.slave.openstack.org',
    sysadmins => hiera('sysadmins'),
  }
  class { 'openstack_project::glancetest':
    s3_store_access_key   => hiera('s3_store_access_key'),
    s3_store_secret_key   => hiera('s3_store_secret_key'),
    s3_store_bucket       => hiera('s3_store_bucket'),
    swift_store_user      => hiera('swift_store_user'),
    swift_store_key       => hiera('swift_store_key'),
    swift_store_container => hiera('swift_store_container'),
  }
}

node /^.*\.jclouds\.openstack\.org$/ {
  class { 'openstack_project::bare_slave':
    certname => 'jclouds.openstack.org',
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
