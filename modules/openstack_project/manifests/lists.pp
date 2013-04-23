# == Class: openstack_project::lists
#
class openstack_project::lists($listadmins = '') {
  # Using openstack_project::template instead of openstack_project::server
  # because the exim config on this machine is almost certainly
  # going to be more complicated than normal.
  class { 'openstack_project::template':
    iptables_public_tcp_ports => [25, 80, 465],
  }

  class { 'exim':
    sysadmin        => $listadmins,
    mailman_domains => ['lists.openstack.org'],
  }

  class { 'mailman':
    vhost_name => 'lists.openstack.org',
  }

  maillist { 'footest':
    ensure      => present,
    admin       => 'foo@openstack.org',
    password    => $listpassword,
    description => 'Foo Testing Bar',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  realize (
    User::Virtual::Localuser['oubiwann'],
    User::Virtual::Localuser['smaffulli'],
  )
}
