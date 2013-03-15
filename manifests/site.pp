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
    github_oauth_token              => hiera('gerrit_github_token'),
    github_project_username         => hiera('github_project_username'),
    github_project_password         => hiera('github_project_password'),
    mysql_password                  => hiera('gerrit_mysql_password'),
    mysql_root_password             => hiera('gerrit_mysql_root_password'),
    email_private_key               => hiera('gerrit_email_private_key'),
    gerritbot_password              => hiera('gerrit_gerritbot_password'),
    ssl_cert_file_contents          => hiera('gerrit_ssl_cert_file_contents'),
    ssl_key_file_contents           => hiera('gerrit_ssl_key_file_contents'),
    ssl_chain_file_contents         => hiera('gerrit_ssl_chain_file_contents'),
    ssh_dsa_key_contents            => hiera('gerrit_ssh_dsa_key_contents'),
    ssh_dsa_pubkey_contents         => hiera('gerrit_ssh_dsa_pubkey_contents'),
    ssh_rsa_key_contents            => hiera('gerrit_ssh_rsa_key_contents'),
    ssh_rsa_pubkey_contents         => hiera('gerrit_ssh_rsa_pubkey_contents'),
    ssh_project_rsa_key_contents    => hiera('gerrit_project_ssh_rsa_key_contents'),
    ssh_project_rsa_pubkey_contents => hiera('gerrit_project_ssh_rsa_pubkey_contents'),
    lp_sync_key                     => hiera('gerrit_lp_sync_key'),
    lp_sync_pubkey                  => hiera('gerrit_lp_sync_pubkey'),
    lp_sync_consumer_key            => hiera('gerrit_lp_consumer_key'),
    lp_sync_token                   => hiera('gerrit_lp_access_token'),
    lp_sync_secret                  => hiera('gerrit_lp_access_secret'),
    contactstore_appsec             => hiera('gerrit_contactstore_appsec'),
    contactstore_pubkey             => hiera('gerrit_contactstore_pubkey'),
    sysadmins                       => hiera('sysadmins'),
  }
}

node 'review-dev.openstack.org' {
  class { 'openstack_project::review_dev':
    github_oauth_token              => hiera('gerrit_dev_github_token'),
    github_project_username         => hiera('github_dev_project_username'),
    github_project_password         => hiera('github_dev_project_password'),
    mysql_password                  => hiera('gerrit_dev_mysql_password'),
    mysql_root_password             => hiera('gerrit_dev_mysql_root_password'),
    email_private_key               => hiera('gerrit_dev_email_private_key'),
    contactstore_appsec             => hiera('gerrit_dev_contactstore_appsec'),
    contactstore_pubkey             => hiera('gerrit_dev_contactstore_pubkey'),
    ssh_dsa_key_contents            => hiera('gerrit_dev_ssh_dsa_key_contents'),
    ssh_dsa_pubkey_contents         => hiera('gerrit_dev_ssh_dsa_pubkey_contents'),
    ssh_rsa_key_contents            => hiera('gerrit_dev_ssh_rsa_key_contents'),
    ssh_rsa_pubkey_contents         => hiera('gerrit_dev_ssh_rsa_pubkey_contents'),
    ssh_project_rsa_key_contents    => hiera('gerrit_dev_project_ssh_rsa_key_contents'),
    ssh_project_rsa_pubkey_contents => hiera('gerrit_dev_project_ssh_rsa_pubkey_contents'),
    lp_sync_key                     => hiera('gerrit_dev_lp_sync_key'),
    lp_sync_pubkey                  => hiera('gerrit_dev_lp_sync_pubkey'),
    lp_sync_consumer_key            => hiera('gerrit_dev_lp_consumer_key'),
    lp_sync_token                   => hiera('gerrit_dev_lp_access_token'),
    lp_sync_secret                  => hiera('gerrit_dev_lp_access_secret'),
    sysadmins                       => hiera('sysadmins'),
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
}

node 'jenkins-dev.openstack.org' {
  class { 'openstack_project::jenkins_dev':
    sysadmins => hiera('sysadmins'),
  }
}

node 'cacti.openstack.org' {
  class { 'openstack_project::cacti':
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

node 'graphite.openstack.org' {
  class { 'openstack_project::graphite':
    sysadmins               => hiera('sysadmins'),
    graphite_admin_user     => hiera('graphite_admin_user'),
    graphite_admin_email    => hiera('graphite_admin_email'),
    graphite_admin_password => hiera('graphite_admin_password'),
    statsd_hosts            => ['jenkins.openstack.org',
                                'devstack-launch.slave.openstack.org',
                                'zuul.openstack.org'],
  }
}

node 'groups.openstack.org' {
  class { 'openstack_project::groups':
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
    ssl_cert_file_contents  => hiera('etherpad_ssl_cert_file_contents'),
    ssl_key_file_contents   => hiera('etherpad_ssl_key_file_contents'),
    ssl_chain_file_contents => hiera('etherpad_ssl_chain_file_contents'),
    database_password       => hiera('etherpad_db_password'),
    sysadmins               => hiera('sysadmins'),
  }
}

node 'etherpad-dev.openstack.org' {
  class { 'openstack_project::etherpad_dev':
    database_password       => hiera('etherpad-dev_db_password'),
    sysadmins               => hiera('sysadmins'),
  }
}

node 'wiki.openstack.org' {
  class { 'openstack_project::wiki':
    mysql_root_password     => hiera('wiki_db_password'),
    sysadmins               => hiera('sysadmins'),
    ssl_cert_file_contents  => hiera('wiki_ssl_cert_file_contents'),
    ssl_key_file_contents   => hiera('wiki_ssl_key_file_contents'),
    ssl_chain_file_contents => hiera('wiki_ssl_chain_file_contents'),
  }
}

node 'puppet-dashboard.openstack.org' {
  class { 'openstack_project::dashboard':
    password        => hiera('dashboard_password'),
    mysql_password  => hiera('dashboard_mysql_password'),
    sysadmins       => hiera('sysadmins'),
  }
}

node 'logstash.openstack.org' {
  class { 'openstack_project::logstash':
    sysadmins => hiera('sysadmins'),
  }
}

# A machine to run ODSREG in preparation for summits.
node 'summit.openstack.org' {
  class { 'openstack_project::summit':
    sysadmins => hiera('sysadmins'),
  }
}

# A machine to serve static content.
node 'static.openstack.org' {
  class { 'openstack_project::static':
    sysadmins => hiera('sysadmins'),
  }
}

node 'zuul.openstack.org' {
  class { 'openstack_project::zuul':
    jenkins_host         => 'jenkins.openstack.org',
    jenkins_url          => 'https://jenkins.openstack.org',
    jenkins_user         => hiera('jenkins_api_user'),
    jenkins_apikey       => hiera('jenkins_api_key'),
    gerrit_server        => 'review.openstack.org',
    gerrit_user          => 'jenkins',
    zuul_ssh_private_key => hiera('jenkins_ssh_private_key_contents'),
    url_pattern          => 'http://logs.openstack.org/{change.number}/{change.patchset}/{pipeline.name}/{job.name}/{build.number}',
    sysadmins            => hiera('sysadmins'),
    statsd_host          => 'graphite.openstack.org',
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

node 'devstack-launch.slave.openstack.org' {
  class { 'openstack_project::devstack_launch_slave':
    jenkins_api_user => hiera('jenkins_api_user'),
    jenkins_api_key  => hiera('jenkins_api_key'),
    jenkins_ssh_private_key => hiera('jenkins_ssh_private_key_contents')
  }
}

node 'tx.slave.openstack.org' {
  class { 'openstack_project::translation_slave':
    transifex_username => 'openstackjenkins',
    transifex_password => hiera('transifex_password')
  }
}

node 'pypi.slave.openstack.org' {
  class { 'openstack_project::pypi_slave':
    pypi_username => 'openstackci',
    pypi_password => hiera('pypi_password')
  }
}

node /^quantal.*\.slave\.openstack\.org$/ {
  include openstack_project::puppet_cron
  class { 'openstack_project::slave':
    certname  => 'quantal.slave.openstack.org',
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
  include jenkins::cgroups
  include ulimit
  ulimit::conf { 'limit_jenkins_procs':
    limit_domain => 'jenkins',
    limit_type   => 'hard',
    limit_item   => 'nproc',
    limit_value  => '256'
  }
}

node /^precise.*\.slave\.openstack\.org$/ {
  include openstack_project::puppet_cron
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
  include jenkins::cgroups
  include ulimit
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
  include jenkins::cgroups
  include ulimit
  ulimit::conf { 'limit_jenkins_procs':
    limit_domain => 'jenkins',
    limit_type   => 'hard',
    limit_item   => 'nproc',
    limit_value  => '256'
  }
}


node /^rhel6.*\.slave\.openstack\.org$/ {
  include openstack_project::puppet_cron
  class { 'openstack_project::slave':
    certname  => 'rhel6.slave.openstack.org',
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
  include jenkins::cgroups
  include ulimit
  ulimit::conf { 'limit_jenkins_procs':
    limit_domain => 'jenkins',
    limit_type   => 'hard',
    limit_item   => 'nproc',
    limit_value  => '256'
  }
}


node /^.*\.jclouds\.openstack\.org$/ {
  class { 'openstack_project::bare_slave':
    certname => 'jclouds.openstack.org',
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
