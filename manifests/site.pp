#
# Default: should at least behave like an openstack server
#
node default {
  include openstack_project::puppet_cron
  include openstack_project::server
}

#
# Long lived servers:
#
node "review.openstack.org" {
  class { 'openstack_project::review':
    github_oauth_token => hiera('gerrit_github_token'),
    mysql_password => hiera('gerrit_mysql_password'),
    mysql_root_password => hiera('gerrit_mysql_root_password'),
    email_private_key => hiera('gerrit_email_private_key'),
    gerritbot_password => hiera('gerrit_gerritbot_password'),
  }
}

node "gerrit-dev.openstack.org", "review-dev.openstack.org" {
  class { 'openstack_project::review_dev':
    github_oauth_token => hiera('gerrit_dev_github_token'),
    mysql_password => hiera('gerrit_dev_mysql_password'),
    mysql_root_password => hiera('gerrit_dev_mysql_root_password'),
    email_private_key => hiera('gerrit_dev_email_private_key')
  }
}

node "jenkins.openstack.org" {
  class { 'openstack_project::jenkins':
    jenkins_jobs_password => hiera('jenkins_jobs_password'),
  }
  class { "openstack_project::zuul":
    jenkins_server => "https://$fqdn",
    jenkins_user => 'hudson-openstack',
    jenkins_apikey => hiera('zuul_jenkins_apikey'),
    gerrit_server => 'review.openstack.org',
    gerrit_user => 'jenkins',
    url_pattern => 'http://logs.openstack.org/{change.number}/{change.patchset}/{pipeline.name}/{job.name}/{build.number}'
  }
}

node "jenkins-dev.openstack.org" {
  include openstack_project::jenkins_dev
}

node "community.openstack.org" {
  include openstack_project::community
}

node "ci-puppetmaster.openstack.org" {
  include openstack_project::puppetmaster
}

node "lists.openstack.org" {
  class { 'openstack_project::lists':
    listadmins => hiera('listadmins'),
  }
}

node "paste.openstack.org" {
  include openstack_project::paste
}

node "planet.openstack.org" {
  include openstack_project::planet
}

node "eavesdrop.openstack.org" {
  class { 'openstack_project::eavesdrop':
    nickpass => hiera('openstack_meetbot_password'),
  }
}

node "pypi.openstack.org" {
  include openstack_project::pypi
}

node 'etherpad.openstack.org' {
  class { 'openstack_project::etherpad':
    etherpad_crt => hiera('etherpad_crt'),
    etherpad_key => hiera('etherpad_key'),
    database_password => hiera('etherpad_db_password'),
  }
}

node 'wiki.openstack.org' {
  class { 'openstack_project::wiki':
    mysql_root_password => hiera('wiki_db_password'),
  }
}

node 'puppet-dashboard.openstack.org' {
  class { 'openstack_project::dashboard':
    password => hiera('dashboard_password'),
    mysql_password => hiera('dashboard_mysql_password'),
  }
}

# A machine to serve static content.
node 'static.openstack.org' {
  include openstack_project::static
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

# Rollout cgroups to precise slaves.
node /^precise.*\.slave\.openstack\.org$/ {
  include openstack_project::puppet_cron
  class { 'openstack_project::slave':
    certname => 'precise.slave.openstack.org',
  }
  class { 'openstack_project::glancetest':
    s3_store_access_key => hiera('s3_store_access_key'),
    s3_store_secret_key => hiera('s3_store_secret_key'),
    s3_store_bucket => hiera('s3_store_bucket'),
    swift_store_user => hiera('swift_store_user'),
    swift_store_key => hiera('swift_store_key'),
    swift_store_container => hiera('swift_store_container'),
  }

  include ulimit
  ulimit::conf { 'limit_jenkins_procs':
    limit_domain => 'jenkins',
    limit_type   => 'hard',
    limit_item   => 'nproc',
    limit_value  => '256'
  }
  include jenkins::cgroups
}

node /^oneiric.*\.slave\.openstack\.org$/ {
  include openstack_project::puppet_cron
  class { 'openstack_project::slave':
    certname => 'oneiric.slave.openstack.org',
  }
  class { 'openstack_project::glancetest':
    s3_store_access_key => hiera('s3_store_access_key'),
    s3_store_secret_key => hiera('s3_store_secret_key'),
    s3_store_bucket => hiera('s3_store_bucket'),
    swift_store_user => hiera('swift_store_user'),
    swift_store_key => hiera('swift_store_key'),
    swift_store_container => hiera('swift_store_container'),
  }
}

node /^.*\.jclouds\.openstack\.org$/ {
  class { 'openstack_project::bare_slave':
    certname => 'jclouds.openstack.org',
  }
} 
