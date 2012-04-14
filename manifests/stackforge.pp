import "doc_server" # TODO: refactor out of module
import "users"
#
# Abstract classes:
#
class openstack_base ($iptables_public_tcp_ports) {
  include openstack_project::users
  include ssh
  include snmpd
  include exim
  include sudoers

  class { 'iptables':
    public_tcp_ports => $iptables_public_tcp_ports,
  }

  file { '/etc/profile.d/Z98-byobu.sh':
    ensure => 'absent'
  }

  package { "ntp":
    ensure => installed
  }

  package { "popularity-contest":
    ensure => purged
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
}

# A template host with no running services
class openstack_template ($iptables_public_tcp_ports) {
  class { 'openstack_base':
    iptables_public_tcp_ports => $iptables_public_tcp_ports
  }
  realize (
    User::Virtual::Localuser["mordred"],
    User::Virtual::Localuser["corvus"],
    User::Virtual::Localuser["soren"],
    User::Virtual::Localuser["linuxjedi"],
    User::Virtual::Localuser["devananda"],
  )
}

# A server that we expect to run for some time
class openstack_server ($iptables_public_tcp_ports) {
  class { 'openstack_template':
    iptables_public_tcp_ports => $iptables_public_tcp_ports
  }
}

class openstack_jenkins_slave {
  class { 'openstack_server':
    iptables_public_tcp_ports => []
  }
  class { 'jenkins_slave':
    ssh_key => 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCvlHx1TM9y6Y+oWJwPQP1jDejQYLA5MaTgD2oQOgQapSAWWU3f9/xcKKF4I5cC833xrSqFCqpstuWt5FdtO6qL5KMqGeVOwTCgcH0uGHciSF/zxBVpHp2n3rHLb0Fibyz/ys2kI+9J/hD0+GlVNQ/U8h9PZPMLFoJIZz5ep5WBszLM5z4vymBZ3GeytD8hk1BW0GLYi9vYWFrwoCTH6o6xRtdKajNE/9NcRGXjkY+SW7EGvqTAfLdsQ8q23MIO2ZX6YOpnmxAmR3OyNEOMo7Y/XCWjqTGWhQ669YaFxagS65f7EGCGwhhgQPtReDwkW88yTGhU3fZjS6Rc3BymTsnx jenkins@jenkins.stackforge.org'
  }
}

#
# Default: should at least behave like an openstack server
#

node default {
  class { 'openstack_server':
    iptables_public_tcp_ports => []
  }
}

#
# Long lived servers:
#
node "puppet.stackforge.org" {
  class { 'openstack_server':
    iptables_public_tcp_ports => [8140]
  }
}

node "review.stackforge.org" {
  class { 'openstack_server':
    iptables_public_tcp_ports => [80, 443, 29418]
  }
  class { 'gerrit':
    canonicalweburl => "https://review.stackforge.org/",
    email => "review@stackforge.org",
    github_projects => [ {
                         name => 'stackforge/MRaaS',
                         close_pull => 'true'
                         }, {
                         name => 'stackforge/reddwarf',
                         close_pull => 'true'
                         } ],
    logo => 'stackforge.png',
    gerrit_ssh_user => 'update',
    gerrit_ssh_key_file => 'id_rsa',
    gerrit_project => 'stackforge'
  }
}

node "jenkins.stackforge.org" {
  class { 'openstack_server':
    iptables_public_tcp_ports => [80, 443, 4155]
  }
  class { 'jenkins_master':
    serveradmin => 'webmaster@stackforge.org',
    site => 'jenkins.stackforge.org',
    logo => 'stackforge.png'
  }

  class { "jenkins_jobs":
    site => "stackforge",
    projects => ["reddwarf"]
  }
}

#
# Jenkins slaves:
#
node /^build.*\.slave\.stackforge\.org$/ {
  include openstack_jenkins_slave
}

