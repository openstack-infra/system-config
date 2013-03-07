# == Class: openstack_project::pypi
#
class openstack_project::pypi (
  $sysadmins = []
) {
  include openstack_project::tmpcleanup
  include openstack_project::automatic_upgrades

  # include jenkins slave so that build deps are there for the pip download
  class { 'jenkins::slave':
    ssh_key => '',
    user    => false,
  }

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
    sysadmins                 => $sysadmins,
  }

  class { 'pypimirror':
    mirror_config => '/etc/openstackci/pypi-mirror.yaml',
  }

  file { '/etc/openstackci':
    ensure  => directory,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
  }

  file { '/etc/openstackci/pypi-mirror.yaml':
    ensure => present,
    source => 'puppet:///modules/openstack_project/pypi-mirror.yaml',
  }

}
