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

class openstack_cron {
  cron { "updatepuppet":
    user => root,
    minute => "*/15",
    command => 'apt-get update >/dev/null 2>&1 ; sleep $((RANDOM\%600)) && cd /root/openstack-ci-puppet && /usr/bin/git pull -q && puppet apply -l /tmp/manifest.log --modulepath=/root/openstack-ci-puppet/modules manifests/site.pp',
    environment => "PATH=/var/lib/gems/1.8/bin:/usr/bin:/bin:/usr/sbin:/sbin",
  }
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
  include openstack_cron
}

class openstack_jenkins_slave {
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
  class { 'openstack_server':
    iptables_public_tcp_ports => []
  }
}

#
# Long lived servers:
#
node "gerrit.openstack.org" {
  class { 'openstack_server':
    iptables_public_tcp_ports => [80, 443, 29418]
  }
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
                         name => 'openstack-ci/git-review',
                         close_pull => 'true'
                         }, {
                         name => 'openstack-ci/lodgeit',
                         close_pull => 'true'
                         }, {
                         name => 'openstack/openstack-common',
                         close_pull => 'true'
                         }, {
                         name => 'openstack-dev/openstack-nose',
                         close_pull => 'true'
                         } ],
    logo => 'openstack.png'
  }
}

node "gerrit-dev.openstack.org" {
  class { 'openstack_server':
    iptables_public_tcp_ports => [80, 443, 29418]
  }

  class { 'gerrit':
    canonicalweburl => "https://review-dev.openstack.org/",
    email => "review-dev@openstack.org",
    github_projects => [ {
                         name => 'gtest-org/test',
                         close_pull => 'true'
                         } ],
    logo => 'openstack.png'
  }
}

node "jenkins.openstack.org" {
  class { 'openstack_server':
    iptables_public_tcp_ports => [80, 443, 4155]
  }
  class { 'jenkins_master':
    site => 'jenkins.openstack.org',
    serveradmin => 'webmaster@openstack.org',
    logo => 'openstack.png'
  }
}

node "jenkins-dev.openstack.org" {
 class { 'openstack_server':
    iptables_public_tcp_ports => [80, 443, 4155]
  } 
  class { 'jenkins_master':
    site => 'openstack'
  }
}

node "community.openstack.org" {
  class { 'openstack_server':
    iptables_public_tcp_ports => [80, 443, 8099, 8080]
  }

  realize (
    User::Virtual::Localuser["smaffulli"],
  )
}

node "docs.openstack.org" {
  class { 'openstack_server':
    iptables_public_tcp_ports => []
  }
  include doc_server
}

node "paste.openstack.org" {
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
  class { 'openstack_server':
    iptables_public_tcp_ports => [80]
  }
  include planet

  planet::site { "openstack":
    git_url => "https://github.com/openstack/openstack-planet.git"
  }
}

# A bare machine, but with a jenkins user
node /^.*\.template\.openstack\.org$/ {
  include openstack_template
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
  include openstack_jenkins_slave
}

node /^dev.*\.slave\.openstack\.org$/ {
  include openstack_jenkins_slave
}

node /^oneiric.*\.slave\.openstack\.org$/ {
  include openstack_jenkins_slave

  package { "tox":
    ensure => latest,
    provider => pip,
    require => Package[python-pip],
  }
}

