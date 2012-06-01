import "users"
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
               "python-virtualenv"]
  package { $packages: ensure => "latest" }

  realize (
    User::Virtual::Localuser["mordred"],
    User::Virtual::Localuser["corvus"],
    User::Virtual::Localuser["soren"],
    User::Virtual::Localuser["linuxjedi"],
    User::Virtual::Localuser["devananda"],
  )
}

# A template host with no running services
class openstack_template ($iptables_public_tcp_ports) {
  include openstack_base
  include ssh
  include snmpd

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
               "bzr",
               "byobu"]
  package { $packages: ensure => "latest" }
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
                 'devananda.vdv@gmail.com']
  }
}
