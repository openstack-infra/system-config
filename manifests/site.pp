import "openstack"

class openstack_cron {
  include logrotate
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
    ssh_key => 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAtioTW2wh3mBRuj+R0Jyb/mLt5sjJ8dEvYyA8zfur1dnqEt5uQNLacW4fHBDFWJoLHfhdfbvray5wWMAcIuGEiAA2WEH23YzgIbyArCSI+z7gB3SET8zgff25ukXlN+1mBSrKWxIza+tB3NU62WbtO6hmelwvSkZ3d7SDfHxrc4zEpmHDuMhxALl8e1idqYzNA+1EhZpbcaf720mX+KD3oszmY2lqD1OkKMquRSD0USXPGlH3HK11MTeCArKRHMgTdIlVeqvYH0v0Wd1w/8mbXgHxfGzMYS1Ej0fzzJ0PC5z5rOqsMqY1X2aC1KlHIFLAeSf4Cx0JNlSpYSrlZ/RoiQ== hudson@hudson'
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
node "gerrit.openstack.org", "review.openstack.org" {
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
    email => "review@openstack.org",
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
                         } ],
    upstream_projects => [ {
                         name => 'openstack-ci/gerrit',
                         remote => 'https://gerrit.googlesource.com/gerrit'
                         } ],
    logo => 'openstack.png',
    war => 'http://ci.openstack.org/tarballs/gerrit-2.3-7-g1f029ab.war',
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
    war => 'http://ci.openstack.org/tarballs/gerrit-2.3-7-g1f029ab.war',
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
}

node "jenkins-dev.openstack.org" {
  include openstack_cron
  class { 'openstack_server':
    iptables_public_tcp_ports => [80, 443, 4155]
  } 
  class { 'jenkins_master':
    site => 'openstack',
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
    mailman_domains => ['lists.openstack.org'],
  }

  class { 'mailman':
    mailman_host => 'lists.openstack.org'
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
  class { 'openstack_server':
    iptables_public_tcp_ports => [80]
  }
  class { "pypimirror":
    base_url => "http://pypi.openstack.org",
  }
}

# A bare machine, but with a jenkins user
node /^.*\.template\.openstack\.org$/ {
  class { 'openstack_template':
    iptables_public_tcp_ports => []
  }
  # This sets up a user with jenkins ssh key and adds it to the sudo group.
  # Don't do that on regular jenkins slaves, only on lowest-privilege test
  # hosts, such as the devstack hosts.
  realize(
     User::Virtual::Localuser["jenkins"],
  )
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

