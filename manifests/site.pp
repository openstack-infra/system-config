import "doc_server" # TODO: refactor out of module
import "users"
#
# Abstract classes:
#
class openstack_base {
  include openstack_project::users
  include ssh
  include snmpd
  include exim
  include sudoers

  class { 'iptables':
    public_tcp_ports => $iptables_public_tcp_ports,
  }
  
  package { "ntp":
    ensure => installed
    }

  service { 'ntpd':
    name       => 'ntp',
    ensure     => running,
    enable     => true,
    hasrestart => true,
    require => Package['ntp'],
  }

  $packages = ["python-software-properties",
               "puppet",
               "bzr",
               "git",
               "python-setuptools",
               "python-virtualenv",
               "byobu"]
  package { $packages: ensure => "latest" }

  cron { "updatepuppet":
    user => root,
    minute => "*/15",
    command => 'apt-get update >/dev/null 2>&1 ; sleep $((RANDOM\%600)) && cd /root/openstack-ci-puppet && /usr/bin/git pull -q && /var/lib/gems/1.8/bin/puppet apply -l /tmp/manifest.log --modulepath=/root/openstack-ci-puppet/modules manifests/site.pp',
  }
}

class openstack_server {
  include openstack_base
  realize (
    User::Virtual::Localuser["mordred"],
    User::Virtual::Localuser["corvus"],
    User::Virtual::Localuser["soren"],
  )

}

class openstack_jenkins_slave {
  include openstack_server
  include jenkins_slave

}

#
# Default: should at least behave like an openstack server
#

node default {
  include openstack_server
}

#
# Long lived servers:
#
node "gerrit.openstack.org" {
  $iptables_public_tcp_ports = [80, 443, 29418]
  include openstack_server
  class { 'gerrit':
    canonicalweburl => "https://review.openstack.org/",
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
                         } ]
  }
}

node "gerrit-dev.openstack.org" {
  $iptables_public_tcp_ports = [80, 443, 29418]
  include openstack_server
 
  class { 'gerrit':
    canonicalweburl => "https://review-dev.openstack.org/",
    email => "review-dev@openstack.org",
    github_projects => [ {
                         name => 'gtest-org/test',
                         close_pull => 'true'
                         } ]
  }
}

node "community.openstack.org" {
  $iptables_public_tcp_ports = [80, 443, 8099, 8080]
  include openstack_server

  realize (
    User::Virtual::Localuser["smaffulli"],
  )
}

node "docs.openstack.org" {
  include openstack_server
  include doc_server
}

node "devstack-oneiric.template.openstack.org" {
  include openstack_server
  include devstack_host
}


#
# Jenkins slaves:
#
node /^.*\.slave\.openstack\.org$/ {
  include openstack_jenkins_slave
}

node /^deploy.*.openstack\.org$/ {
  include openstack_jenkins_slave
  include orchestra
}
