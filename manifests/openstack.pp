import "users"
#
# Abstract classes:
#
class openstack_base ($iptables_public_tcp_ports) {
  include openstack_project::users
  include ssh
  include snmpd
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
  class { 'exim':
    sysadmin => ['corvus@inaugust.com',
                 'mordred@inaugust.com',
                 'andrew@linuxjedi.co.uk',
                 'devananda.vdv@gmail.com']
  }
}
