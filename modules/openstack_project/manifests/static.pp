class openstack_project::static
{

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443]
  }

  include apache

  apache::vhost { 'tarballs.openstack.org':
    port     => 80,
    priority => '50',
    docroot  => '/srv/static/tarballs',
    require  => File['/srv/static/tarballs'],
  }

  apache::vhost { 'ci.openstack.org':
    port     => 80,
    priority => '50',
    docroot  => '/srv/static/ci',
    require  => File['/srv/static/ci'],
  }

  apache::vhost { 'logs.openstack.org':
    port     => 80,
    priority => '50',
    docroot  => '/srv/static/logs',
    require  => File['/srv/static/logs'],
  }

  file { '/srv/static':
    ensure => directory
  }

  file { '/srv/static/tarballs':
    ensure => directory
  }

  file { '/srv/static/ci':
    ensure => directory
  }

  file { '/srv/static/logs':
    ensure => directory
  }

}
