import "users"

$openstack_project_list = [ {
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
     name => 'openstack-dev/pbr',
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
     }, {
     name => 'stackforge/MRaaS',
     close_pull => 'true'
     }, {
     name => 'stackforge/reddwarf',
     close_pull => 'true'
     }, {
     name => 'stackforge/ceilometer',
     close_pull => 'true'
     }, {
     name => 'heat-api/heat',
     close_pull => 'true'
     }
  ]

#
# Abstract classes:
#
class openstack_base {
  include openstack_project::users
  include sudoers

  file { '/etc/profile.d/Z98-byobu.sh':
    ensure => 'absent'
  }

  package { "popularity-contest":
    ensure => purged
  }

  $packages = ["puppet",
               "git",
               "python-setuptools",
               "python-virtualenv",
               "python-software-properties",
               "bzr",
               "byobu",
               "emacs23-nox"]
  package { $packages: ensure => "present" }

  realize (
    User::Virtual::Localuser["mordred"],
    User::Virtual::Localuser["corvus"],
    User::Virtual::Localuser["soren"],
    User::Virtual::Localuser["linuxjedi"],
    User::Virtual::Localuser["devananda"],
    User::Virtual::Localuser["clarkb"],
  )
}

# A template host with no running services
class openstack_template ($iptables_public_tcp_ports) {
  include openstack_base
  include ssh
  include snmpd
  include apt::unattended-upgrades
  
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
}

# A server that we expect to run for some time
class openstack_server ($iptables_public_tcp_ports) {
  class { 'openstack_template':
    iptables_public_tcp_ports => $iptables_public_tcp_ports
  }
  class { 'exim':
    sysadmin => ['corvus@inaugust.com',
                 'mordred@inaugust.com',
                 'andrew@linuxjedi.co.uk',
                 'devananda.vdv@gmail.com',
                 'clark.boylan@gmail.com']
  }
}
