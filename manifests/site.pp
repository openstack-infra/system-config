import "openstack_admins_users"    #TODO: refactor
import "openstack_ci_admins_users" #TODO: refactor
import "doc_server" # TODO: refactor out of module

#
# Abstract classes:
#
class openstack_base {
  include ssh

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
}

class openstack_server {
  include openstack_base
  include openstack_admins_users
}

class openstack_jenkins_slave {
  include openstack_base
  include openstack_ci_admins_users
  include jenkins_slave
}

#
# Long lived servers:
#
node "gerrit.openstack.org", "gerrit-dev.openstack.org" {
  include openstack_server
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

  apt::ppa { "ppa:nova-core/trunk":
    ensure => present
  }
  apt::ppa { "ppa:swift-core/trunk":
    ensure => present
  }

  $slave_packages = ["python-eventlet",
                     "python-ldap",
                     "python-memcache",
                     "python-paste",
                     "python-routes",
                     "python-sqlalchemy",
                     "python-webob",
		     "python-nova",
		     "python-swift"]

  package { $slave_packages:
    ensure => "latest",
    require => [Apt::Ppa["ppa:nova-core/trunk"],
                Apt::Ppa["ppa:swift-core/trunk"]]
  }
}

node /^quantum(-\d+)?\.slave\.openstack\.org$/ {
  include openstack_jenkins_slave

  apt::ppa { "ppa:nova-core/trunk":
    ensure => present
  }

  $slave_packages = ["python-eventlet",
                     "python-paste",
                     "python-routes",
                     "python-sqlalchemy",
                     "python-gflags",
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

  apt::ppa { "ppa:nova-core/trunk":
    ensure => present
  }

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
