import "openstack_admins_users"    #TODO: refactor
import "openstack_ci_admins_users" #TODO: refactor
import "doc_server" # TODO: refactor out of module

#
# Abstract classes:
#
class openstack_base {
  include ssh
  include exim
  
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
    command => 'sleep $((RANDOM\%600)) && cd /root/openstack-ci-puppet && /usr/bin/git pull -q && /var/lib/gems/1.8/bin/puppet apply -l /tmp/manifest.log --modulepath=/root/openstack-ci-puppet/modules manifests/site.pp',
  }
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
node "gerrit.openstack.org" {
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
                         } ]
  }

  class { 'iptables':
    public_tcp_ports => [80, 443, 29418]
  }
}

node "gerrit-dev.openstack.org" {
  include openstack_server
  class { 'gerrit':
    canonicalweburl => "https://review-dev.openstack.org/",
    email => "review-dev@openstack.org",
    github_projects => [ {
                         name => 'gtest-org/test',
                         close_pull => 'true'
                         } ]
  }

  class { 'iptables':
    public_tcp_ports => [80, 443, 29418]
  }
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
                     "python-unittest2",
                     "python-dtest",
		     "python-swift"]

  package { $slave_packages:
    ensure => "latest",
    require => [Apt::Ppa["ppa:keystone-core/trunk"],
                Apt::Ppa["ppa:nova-core/trunk"],
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

node /^driver(\d+)\.1918\.openstack\.org$/ {
  include openstack_jenkins_slave

  group { 'termie':
    ensure => 'present'
  }

  user { 'termie':
    ensure => 'present',
    comment => 'Andy Smith',
    home => $operatingsystem ? {
      Darwin => '/Users/termie',
      solaris => '/export/home/termie',
      default => '/home/termie',
    },
    shell => '/bin/bash',
    gid => 'termie',
    groups => ['wheel','sudo','admin'],
    membership => 'minimum',
  }

  file { 'termiehome':
    name => $operatingsystem ? {
      Darwin => '/Users/termie',
      solaris => '/export/home/termie',
      default => '/home/termie',
    },
    owner => 'termie',
    group => 'termie',
    mode => 644,
    ensure => 'directory',
  }


  file { 'termiesshdir':
    name => $operatingsystem ? {
      Darwin => '/Users/termie/.ssh',
      solaris => '/export/home/termie/.ssh',
      default => '/home/termie/.ssh',
    },
    owner => 'termie',
    group => 'termie',
    mode => 700,
    ensure => 'directory',
    require => File['termiehome'],
  }

  file { 'termiekeys':
    name => $operatingsystem ? {
      Darwin => '/Users/termie/.ssh/authorized_keys',
      solaris => '/export/home/termie/.ssh/authorized_keys',
      default => '/home/termie/.ssh/authorized_keys',
    },
    owner => 'termie',
    group => 'termie',
    mode => 640,
    content => "ssh-dss AAAAB3NzaC1kc3MAAACBANGJLz/WD7MCdw9uT1PPGO/j9ONs9zUIvQXCIyzbMywZdcLRfQMBxbrpumSxmB7H5wri/unSkCg2JGeShoyDyaQN0Vt5gQCDaXSJBZd4UJ1H6NEts6ecwRuVYw09jHPlqR5JcoRcsdrh07K4FdggTrqfdhhzbMRI5H18qLZhlHODAAAAFQDrkqKb7DnTRZfwAdKwkVCkKipfdQAAAIAVgJ01asDYIkMCjqP1GFfger/7aq6m5p9dxDfoMHOk6QKK+xiN9kzQAXkCM/qWUYOzYyq6QkXSGHUprr3CbhqIpiqNV2T95PJ5qelDDSu1I3/G738BcbcoNQKl57IkE6q4ASD7YgQ8s8vB9ZsSgt9jdXkFEf8joPYZS26ztlKbKQAAAIEAwaCNdjISOHzNTDkestFajajLw4rfbpS3xMwojlx+ZUmTuKTmqpTYVwqFRarI1c5OlZT58BLzqB+iiH/lTbOSl+Zg+xJ72DnPxhOhueEi7ll7BsZvurm4ObM7EQ27WI9Pb0JWF+V6lo3+iRHozDmKyxRYGzAR9PpGgjj2VHCuf1I= termie@chester\n",
    ensure => 'present',
    require => File['termiesshdir'],
  }

  file { 'termiebashrc':
    name => $operatingsystem ? {
      Darwin => '/Users/termie/.bashrc',
      solaris => '/export/home/termie/.bashrc',
      default => '/home/termie/.bashrc',
    },
    owner => 'termie',
    group => 'termie',
    mode => 640,
    source => "/etc/skel/.bashrc",
    replace => 'false',
    ensure => 'present',
  }

  file { 'termiebash_logout':
    name => $operatingsystem ? {
      Darwin => '/Users/termie/.bash_logout',
      solaris => '/export/home/termie/.bash_logout',
      default => '/home/termie/.bash_logout',
    },
    source => "/etc/skel/.bash_logout",
    owner => 'termie',
    group => 'termie',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'termieprofile':
    name => $operatingsystem ? {
      Darwin => '/Users/termie/.profile',
      solaris => '/export/home/termie/.profile',
      default => '/home/termie/.profile',
    },
    source => "/etc/skel/.profile",
    owner => 'termie',
    group => 'termie',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'termiebazaardir':
    name => $operatingsystem ? {
      Darwin => '/Users/termie/.bazaar',
      solaris => '/export/home/termie/.bazaar',
      default => '/home/termie/.bazaar',
    },
    owner => 'termie',
    group => 'termie',
    mode => 755,
    ensure => 'directory',
    require => File['termiehome'],
  }


  file { 'termiebazaarauth':
    name => $operatingsystem ? {
      Darwin => '/Users/termie/.bazaar/authentication.conf',
      solaris => '/export/home/termie/.bazaar/authentication.conf',
      default => '/home/termie/.bazaar/authentication.conf',
    },
    owner => 'termie',
    group => 'termie',
    mode => 640,
    content => "[Launchpad]\nhost = .launchpad.net\nscheme = ssh\nuser = termie\n",
    ensure => 'present',
    require => File['termiebazaardir'],
  }

}

node /^debuild(-\d+)?\.slave\.openstack\.org$/ {
  include openstack_jenkins_slave
  include cowbuilder
}

node /^packages\.openstack\.org$/ {
  include openstack_jenkins_slave

  class { "apt_server": }
}
