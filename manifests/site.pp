import "openstack"

$jenkins_ssh_key = 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAtioTW2wh3mBRuj+R0Jyb/mLt5sjJ8dEvYyA8zfur1dnqEt5uQNLacW4fHBDFWJoLHfhdfbvray5wWMAcIuGEiAA2WEH23YzgIbyArCSI+z7gB3SET8zgff25ukXlN+1mBSrKWxIza+tB3NU62WbtO6hmelwvSkZ3d7SDfHxrc4zEpmHDuMhxALl8e1idqYzNA+1EhZpbcaf720mX+KD3oszmY2lqD1OkKMquRSD0USXPGlH3HK11MTeCArKRHMgTdIlVeqvYH0v0Wd1w/8mbXgHxfGzMYS1Ej0fzzJ0PC5z5rOqsMqY1X2aC1KlHIFLAeSf4Cx0JNlSpYSrlZ/RoiQ== hudson@hudson'

class openstack_cron {
  include logrotate
  include puppetboot
  cron { "updatepuppet":
    user => root,
    minute => "*/15",
    command => 'apt-get update >/dev/null 2>&1 ; sleep $((RANDOM\%600)) && cd /root/openstack-ci-puppet && /usr/bin/git pull -q && puppet apply -l /var/log/manifest.log --modulepath=/root/openstack-ci-puppet/modules manifests/site.pp',
    environment => "PATH=/var/lib/gems/1.8/bin:/usr/bin:/bin:/usr/sbin:/sbin",
  }
  logrotate::file { 'updatepuppet':
    log => '/var/log/manifest.log',
    options => ['compress', 'delaycompress', 'missingok', 'rotate 7', 'daily', 'notifempty'],
    require => Cron['updatepuppet'],
  }
}

class openstack_jenkins_slave {
  include openstack_cron
  include tmpreaper
  class { 'openstack_server':
    iptables_public_tcp_ports => []
  }
  class { 'jenkins_slave':
    ssh_key => $jenkins_ssh_key
  }
}

#
# Default: should at least behave like an openstack server
#

node default {
  include openstack_cron
  class { 'openstack_server':
    iptables_public_tcp_ports => []
  }
}

#
# Long lived servers:
#

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

node "review.openstack.org" {
  include openstack_cron
  class { 'openstack_server':
    iptables_public_tcp_ports => [80, 443, 29418]
  }
  class { 'gerrit':
    virtual_hostname => 'review.openstack.org',
    canonicalweburl => "https://review.openstack.org/",
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
    github_projects => [ {
                         name => 'openstack/keystone',
                         close_pull => 'true'
                         }, {
                         name => 'openstack/glance',
                         close_pull => 'true'
                         }, {
                         name => 'openstack/swift',
                         close_pull => 'true'
                         }, {
                         name => 'openstack/nova',
                         close_pull => 'true'
                         }, {
                         name => 'openstack/horizon',
                         close_pull => 'true'
                         }, {
                         name => 'openstack/quantum',
                         close_pull => 'true'
                         }, {
                         name => 'openstack/melange',
                         close_pull => 'true'
                         }, {
                         name => 'openstack/tempest',
                         close_pull => 'true'
                         }, {
                         name => 'openstack/openstack-ci',
                         close_pull => 'true'
                         }, {
                         name => 'openstack/openstack-ci-puppet',
                         close_pull => 'true'
                         }, {
                         name => 'openstack/openstack-puppet',
                         close_pull => 'true'
                         }, {
                         name => 'openstack/openstack-chef',
                         close_pull => 'true'
                         }, {
                         name => 'openstack/openstack-manuals',
                         close_pull => 'true'
                         }, {
                         name => 'openstack/compute-api',
                         close_pull => 'true'
                         }, {
                         name => 'openstack/image-api',
                         close_pull => 'true'
                         }, {
                         name => 'openstack/identity-api',
                         close_pull => 'true'
                         }, {
                         name => 'openstack/object-api',
                         close_pull => 'true'
                         }, {
                         name => 'openstack/netconn-api',
                         close_pull => 'true'
                         }, {
                         name => 'openstack-dev/devstack',
                         close_pull => 'true'
                         }, {
                         name => 'openstack-dev/openstack-qa',
                         close_pull => 'true'
                         }, {
                         name => 'openstack/python-novaclient',
                         close_pull => 'true'
                         }, {
                         name => 'openstack/python-glanceclient',
                         close_pull => 'true'
                         }, {
                         name => 'openstack-ci/git-review',
                         close_pull => 'true'
                         }, {
                         name => 'openstack-ci/lodgeit',
                         close_pull => 'true'
                         }, {
                         name => 'openstack-ci/meetbot',
                         close_pull => 'true'
                         }, {
                         name => 'openstack-ci/zuul',
                         close_pull => 'true'
                         }, {
                         name => 'openstack-ci/pypi-mirror',
                         close_pull => 'true'
                         }, {
                         name => 'openstack/openstack-common',
                         close_pull => 'true'
                         }, {
                         name => 'openstack/cinder',
                         close_pull => 'true'
                         }, {
                         name => 'openstack/python-openstackclient',
                         close_pull => 'true'
                         }, {
                         name => 'openstack-dev/openstack-nose',
                         close_pull => 'true'
                         }, {
                         name => 'openstack/python-cinderclient',
                         close_pull => 'true'
                         }, {
                         name => 'openstack/python-swiftclient',
                         close_pull => 'true'
                         } ],
    upstream_projects => [ {
                         name => 'openstack-ci/gerrit',
                         remote => 'https://gerrit.googlesource.com/gerrit'
                         } ],
    logo => 'openstack.png',
    war => 'http://ci.openstack.org/tarballs/gerrit-2.3-7-g1f029ab.war',
    script_user => 'launchpadsync',
    script_key_file => '/home/gerrit2/.ssh/launchpadsync_rsa',
    script_site => 'openstack'
  }
}

node "gerrit-dev.openstack.org", "review-dev.openstack.org" {
  include openstack_cron
  class { 'openstack_server':
    iptables_public_tcp_ports => [80, 443, 29418]
  }

  class { 'gerrit':
    virtual_hostname => 'review-dev.openstack.org',
    canonicalweburl => "https://review-dev.openstack.org/",
    ssl_cert_file => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
    ssl_key_file => '/etc/ssl/private/ssl-cert-snakeoil.key',
    ssl_chain_file => '',
    email => "review-dev@openstack.org",
    github_projects => [ {
                         name => 'gtest-org/test',
                         close_pull => 'true'
                         } ],
    logo => 'openstack.png',
    war => 'http://ci.openstack.org/tarballs/test/gerrit-2.4-10-g008583c.war',
    script_user => 'update',
    script_key_file => '/home/gerrit2/.ssh/id_rsa',
    script_site => 'openstack'
  }
}

node "jenkins.openstack.org" {
  include openstack_cron
  class { 'openstack_server':
    iptables_public_tcp_ports => [80, 443, 4155]
  }
  class { 'jenkins_master':
    site => 'jenkins.openstack.org',
    serveradmin => 'webmaster@openstack.org',
    logo => 'openstack.png',
    ssl_cert_file => '/etc/ssl/certs/jenkins.openstack.org.pem',
    ssl_key_file => '/etc/ssl/private/jenkins.openstack.org.key',
    ssl_chain_file => '/etc/ssl/certs/intermediate.pem',
  }
  class { "jenkins_jobs":
    site => "openstack",
    projects => [
      'cinder',
      'gerrit',
      'glance',
      'horizon',
      'keystone',
      'melange',
      'nova',
      'openstack-ci-puppet',
      'pypi-mirror',
      'python-cinderclient',
      'python-glanceclient',
      'python-keystoneclient',
      'python-melangeclient',
      'python-novaclient',
      'python-openstackclient',
      'python-quantumclient',
      'python-swiftclient',
      'quantum',
      'swift',
      'zuul',
    ]
  }
  class { 'zuul': }
  file { "/etc/zuul/layout.yaml":
    ensure => 'present',
    source => 'puppet:///modules/openstack-ci-config/zuul/layout.yaml'
  }
  file { "/etc/zuul/logging.conf":
    ensure => 'present',
    source => 'puppet:///modules/openstack-ci-config/zuul/logging.conf'
  }
}

node "jenkins-dev.openstack.org" {
  include openstack_cron
  class { 'openstack_server':
    iptables_public_tcp_ports => [80, 443, 4155]
  } 
  class { 'jenkins_master':
    site => 'jenkins-dev.openstack.org',
    serveradmin => 'webmaster@openstack.org',
    logo => 'openstack.png',
    ssl_cert_file => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
    ssl_key_file => '/etc/ssl/private/ssl-cert-snakeoil.key',
    ssl_chain_file => '',
  }
}

node "community.openstack.org" {
  include openstack_cron
  class { 'openstack_server':
    iptables_public_tcp_ports => [80, 443, 8099, 8080]
  }

  realize (
    User::Virtual::Localuser["smaffulli"],
  )
}

node "lists.openstack.org" {
  include openstack_cron

  # Using openstack_template instead of openstack_server
  # because the exim config on this machine is almost certainly
  # going to be more complicated than normal.
  class { 'openstack_template':
    iptables_public_tcp_ports => [25, 80, 465]
  }

  class { 'exim':
    sysadmin => ['corvus@inaugust.com',
                 'mordred@inaugust.com',
                 'andrew@linuxjedi.co.uk',
                 'devananda.vdv@gmail.com',
  		 'duncan@dreamhost.com'],
    mailman_domains => ['stagelists.openstack.org'],
  }

  class { 'mailman':
    mailman_host => 'stagelists.openstack.org'
  }

  realize (
    User::Virtual::Localuser["oubiwann"],
  )
}

node "docs.openstack.org" {
  include openstack_cron
  class { 'openstack_server':
    iptables_public_tcp_ports => []
  }
  include doc_server
}

node "paste.openstack.org" {
  include openstack_cron
  class { 'openstack_server':
    iptables_public_tcp_ports => [80]
  }
  include lodgeit
  lodgeit::site { "openstack":
    port => "5000",
    image => "header-bg2.png"
  }

  lodgeit::site { "drizzle":
    port => "5001"
  }

}

node "planet.openstack.org" {
  include openstack_cron
  class { 'openstack_server':
    iptables_public_tcp_ports => [80]
  }
  include planet

  planet::site { "openstack":
    git_url => "https://github.com/openstack/openstack-planet.git"
  }
}

node "eavesdrop.openstack.org" {
  include openstack_cron
  class { 'openstack_server':
    iptables_public_tcp_ports => [80]
  }
  include meetbot

  meetbot::site { "openstack":
    nick => "openstack",
    network => "FreeNode",
    server => "chat.us.freenode.net:7000",
    url => "eavesdrop.openstack.org",
    channels => "#openstack #openstack-dev #openstack-meeting",
    use_ssl => "True"
  }
}

node "pypi.openstack.org" {
  include openstack_cron

  # include jenkins slave so that build deps are there for the pip download
  class { 'jenkins_slave':
    ssh_key => "",
    user => false
  }

  class { 'openstack_server':
    iptables_public_tcp_ports => [80]
  }

  class { "pypimirror":
    base_url => "http://pypi.openstack.org",
    projects => [
      'cinder',
      'glance',
      'horizon',
      'keystone',
      'melange',
      'nova',
      'openstack-common',
      'python-cinderclient',
      'python-glanceclient',
      'python-keystoneclient',
      'python-melangeclient',
      'python-novaclient',
      'python-openstackclient',
      'python-quantumclient',
      'python-swiftclient',
      'quantum',
      'swift'
      ]
  }
}

node 'etherpadlite.openstack.org' {
  include openstack_cron
  class { 'openstack_server':
    iptables_public_tcp_ports => [22, 80, 443]
  }

  include etherpad_lite
  class { 'etherpad_lite::nginx':
    server_name => 'etherpadlite.openstack.org'
  }
  include etherpad_lite::site
  include etherpad_lite::mysql
}

# A bare machine, but with a jenkins user
node /^.*\.template\.openstack\.org$/ {
  class { 'openstack_template':
    iptables_public_tcp_ports => []
  }
  class { 'jenkins_slave':
    ssh_key => $jenkins_ssh_key,
    sudo => true,
    bare => true
  }
}

#
# Jenkins slaves:
#
node /^build.*\.slave\.openstack\.org$/ {
  include openstack_cron
  include openstack_jenkins_slave
}

node /^dev.*\.slave\.openstack\.org$/ {
  include openstack_cron
  include openstack_jenkins_slave
}

node /^oneiric.*\.slave\.openstack\.org$/ {
  include openstack_cron
  include openstack_jenkins_slave

  package { "tox":
    ensure => latest,
    provider => pip,
    require => Package[python-pip],
  }
}

# bare-bones slaves spun up by jclouds. Specifically need to not set ssh
# login limits, because it screws up jclouds provisioning
node /^.*\.jclouds\.openstack\.org$/ {

  include openstack_base

  class { 'jenkins_slave':
    ssh_key => "",
    user => false
  }
} 
