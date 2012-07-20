import "users"

$openstack_project_list = [
  'heat-api/heat',
  'openstack-ci/git-review',
  'openstack-ci/lodgeit',
  'openstack-ci/meetbot',
  'openstack-ci/pypi-mirror',
  'openstack-ci/zuul',
  'openstack-dev/devstack',
  'openstack-dev/openstack-nose',
  'openstack-dev/openstack-qa',
  'openstack-dev/pbr',
  'openstack/cinder',
  'openstack/compute-api',
  'openstack/glance',
  'openstack/horizon',
  'openstack/identity-api',
  'openstack/image-api',
  'openstack/keystone',
  'openstack/melange',
  'openstack/netconn-api',
  'openstack/nova',
  'openstack/object-api',
  'openstack/openstack-chef',
  'openstack/openstack-ci',
  'openstack/openstack-ci-puppet',
  'openstack/openstack-common',
  'openstack/openstack-manuals',
  'openstack/openstack-puppet',
  'openstack/python-cinderclient',
  'openstack/python-glanceclient',
  'openstack/python-novaclient',
  'openstack/python-openstackclient',
  'openstack/python-swiftclient',
  'openstack/quantum',
  'openstack/swift',
  'openstack/tempest',
  'stackforge/MRaaS',
  'stackforge/ceilometer',
  'stackforge/reddwarf',
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
