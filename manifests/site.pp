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
  include openstack_base
  include jenkins_slave

  apt::ppa { "ppa:nova-core/trunk":
    ensure => present
  }
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
  $iptables_public_tcp_ports = [80, 443, 29418]
  include openstack_server

  realize (
    User::Virtual::Localuser["smaffulli"],
  )
}

node "docs.openstack.org" {
  include openstack_server
  include doc_server
}

#
# Jenkins slaves:
#
node /^burrow-java(-\d+)?\.slave\.openstack\.org$/ {
  include openstack_jenkins_slave

  package { "maven2":
    ensure => latest
  }
}

node /^burrow(-\d+)?\.slave\.openstack\.org$/ {
  include openstack_jenkins_slave

  package { "python-eventlet":
    ensure => latest
  }
}

node /^libburrow(-\d+)?\.slave\.openstack\.org$/ {
  include openstack_jenkins_slave

  $slave_packages = ["build-essential",
                     "libcurl4-gnutls-dev",
                     "libtool",
                     "autoconf",
                     "automake"]
  package { $slave_packages: ensure => "latest" }
}

node /^dashboard(-\d+)?\.slave\.openstack\.org$/ {
  include openstack_jenkins_slave

  package { "python-virtualenv":
    ensure => present
  }
}

node /^glance(-\d+)?\.slave\.openstack\.org$/ {
  include openstack_jenkins_slave

  apt::ppa { "ppa:glance-core/trunk":
    ensure => present
  }

  apt::builddep { "glance":
    ensure => present,
    require => Apt::Ppa["ppa:glance-core/trunk"]
  }

  $slave_packages = ["python-argparse",
                     "python-decorator",
                     "python-eventlet",
                     "python-formencode",
                     "python-greenlet",
                     "python-migrate",
                     "python-mox",
                     "python-netifaces",
                     "python-openid",
                     "python-openssl",
                     "python-paste",
                     "python-pastedeploy",
                     "python-pastescript",
                     "python-routes",
                     "python-scgi",
                     "python-sqlalchemy",
                     "python-sqlalchemy-ext",
                     "python-swift",
                     "python-tempita",
                     "python-webob",
                     "python-xattr"]
  package { $slave_packages: ensure => "latest" }
}

node /^keystone(-\d+)?\.slave\.openstack\.org$/ {
  include openstack_jenkins_slave

  apt::ppa { "ppa:keystone-core/trunk":
    ensure => present
  }
  apt::ppa { "ppa:swift-core/trunk":
    ensure => present
  }

  apt::builddep { "keystone":
    ensure => present,
    require => [Apt::Ppa["ppa:keystone-core/trunk"],
                Apt::Ppa["ppa:nova-core/trunk"],
                Apt::Ppa["ppa:swift-core/trunk"]]
  }
}

node /^quantum(-\d+)?\.slave\.openstack\.org$/ {
  include openstack_jenkins_slave

  $slave_packages = ["python-eventlet",
                     "python-paste",
                     "python-routes",
                     "python-sqlalchemy",
                     "python-gflags",
                     "python-cheetah",
                     "python-webtest",
                     "python-webob"]

  package { $slave_packages:
    ensure => "latest",
    require => Apt::Ppa["ppa:nova-core/trunk"]
  }
}

node /^manuals(-\d+)?\.slave\.openstack\.org$/ {
  include openstack_jenkins_slave

  package { "maven2":
    ensure => latest
  }
}

node /^nova(-\d+)?\.slave\.openstack\.org$/ {
  include openstack_jenkins_slave

  apt::builddep { "nova":
    ensure => present,
    require => Apt::Ppa["ppa:nova-core/trunk"]
  }
}

node /^openstack-ci(-\d+)?\.slave\.openstack\.org$/ {
  include openstack_jenkins_slave
}

node /^swift(-\d+)?\.slave\.openstack\.org$/ {
  include openstack_jenkins_slave

  apt::ppa { "ppa:swift-core/trunk":
    ensure => present
  }

  apt::builddep { "swift":
    ensure => present,
    require => Apt::Ppa["ppa:swift-core/trunk"]
  }
}

node /^driver(\d+)\.1918\.openstack\.org$/ {
  include openstack_jenkins_slave
}

node /^debuild(-\d+)?\.slave\.openstack\.org$/ {
  include openstack_jenkins_slave
  include cowbuilder

  class { "reprepro": }
}

node /^packages\.openstack\.org$/ {
  include openstack_jenkins_slave

  class { "apt_server": }
}
