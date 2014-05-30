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
    repos => {
      'openstack/barbican': {
        'github': 'https://github.com/openstack/barbican'
      },
      'openstack/python-barbicanclient': {
        'github': 'https://github.com/openstack/python-barbicanclient'
      },
      'openstack/cinder': {
        'github': 'https://github.com/openstack/cinder'
      },
      'openstack/python-cinderclient': {
        'github': 'https://github.com/openstack/python-cinderclient'
      },
      'openstack/glance': {
        'github': 'https://github.com/openstack/glance'
      },
      'openstack/python-glanceclient': {
        'github': 'https://github.com/openstack/python-glanceclient'
      },
      'openstack/keystone': {
        'github': 'https://github.com/openstack/keystone'
      },
      'openstack/python-keystoneclient': {
        'github': 'https://github.com/openstack/python-keystoneclient'
      },
      'openstack/marconi': {
        'github': 'https://github.com/openstack/marconi'
      },
      'openstack/python-marconiclient': {
        'github': 'https://github.com/openstack/python-marconiclient'
      },
      'openstack/nova': {
        'github': 'https://github.com/openstack/nova'
      },
      'openstack/python-novaclient': {
        'github': 'https://github.com/openstack/python-novaclient'
      },
      'openstack/swift': {
        'github': 'https://github.com/openstack/swift'
      },
      'openstack/python-swiftclient': {
        'github': 'https://github.com/openstack/python-swiftclient'
      },
    }
  }
}
