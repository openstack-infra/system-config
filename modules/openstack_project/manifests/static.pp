class openstack_project::static(
  $ssh_key=$openstack_project::jenkins_ssh_key
  ) {

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443]
  }

  class { 'jenkins::jenkinsuser':
    ssh_key => $ssh_key
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
