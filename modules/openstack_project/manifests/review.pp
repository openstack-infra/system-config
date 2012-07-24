# Current thinking on Gerrit tuning parameters:

# database.poolLimit:
# This limit must be several units higher than the total number of
# httpd and sshd threads as some request processing code paths may need
# multiple connections.
# database.poolLimit = 1 + max(sshd.threads,sshd.batchThreads) + sshd.streamThreads + sshd.commandStartThreads + httpd.acceptorThreads + httpd.maxThreads 
# http://groups.google.com/group/repo-discuss/msg/4c2809310cd27255
# or "2x sshd.threads"
# http://groups.google.com/group/repo-discuss/msg/269024c966e05d6a

# container.heaplimit:
# core.packedgit*
# http://groups.google.com/group/repo-discuss/msg/269024c966e05d6a

# sshd.threads:
# http://groups.google.com/group/repo-discuss/browse_thread/thread/b91491c185295a71

# httpd.maxWait:
# 12:07 <@spearce> httpd.maxwait defaults to 5 minutes and is how long gerrit
#                  waits for an idle sshd.thread before aboring the http request
# 12:08 <@spearce> ironically
# 12:08 <@spearce> ProjectQosFilter passes this value as minutes
# 12:08 <@spearce> to a method that accepts milliseconds
# 12:09 <@spearce> so. you get 5 milliseconds before aborting
# thus, set it to 5000minutes until the bug is fixed.
class openstack_project::review {
  include openstack_project
  class { 'openstack_project::gerrit':
    ssl_cert_file => '/etc/ssl/certs/review.openstack.org.pem',
    ssl_key_file => '/etc/ssl/private/review.openstack.org.key',
    ssl_chain_file => '/etc/ssl/certs/intermediate.pem',
    email => 'review@openstack.org',
    database_poollimit => '150',    # 1 + 100 + 9 + 2 + 2 + 25 = 139(rounded up)
    container_heaplimit => '8g',
    core_packedgitopenfiles => '4096',
    core_packedgitlimit => '400m',
    core_packedgitwindowsize => '16k',
    sshd_threads => '100',
    httpd_maxwait => '5000min',
    war => 'http://tarballs.openstack.org/ci/gerrit-2.4.1-10-g63110fd.war',
    script_user => 'launchpadsync',
    script_key_file => '/home/gerrit2/.ssh/launchpadsync_rsa',
    github_projects => $openstack_project::project_list,
    github_username => 'openstack-gerrit',
    github_oauth_token => hiera('gerrit_github_token'),
    mysql_password => hiera('gerrit_mysql_password'),
    email_private_key => hiera('gerrit_email_private_key'),
  }
  class { 'gerritbot':
    gerritbot_nick => 'openstackgerrit',
    gerritbot_password => hiera('gerrit_gerritbot_password'),
    gerritbot_server => 'irc.freenode.net',
    gerritbot_user => 'gerritbot'
  }
  class { 'gerrit::remotes':
    upstream_projects => [ {
                         name => 'openstack-ci/gerrit',
                         remote => 'https://gerrit.googlesource.com/gerrit'
                         } ],
  }
}
