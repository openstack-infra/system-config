# == Class: openstack_project::livegrep
#
class openstack_project::livegrep (
  $sysadmins = []
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
    sysadmins                 => $sysadmins,
  }
  include livegrep
  livegrep::site { 'openstack':
    openstack_repos => [
      'nova',
      'python-novaclient',
      'cinder',
      'python-cinderclient',
      'glance',
      'python-glanceclient',
      'swift',
      'python-swiftclient',
      'keystone',
      'python-keystoneclient',
      'marconi',
      'python-marconiclient',
      'barbican',
      'python-barbicanclient',
    ]
  }
}
