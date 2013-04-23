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

maillist { 'legal-discuss':
    ensure      => present,
    admin       => 'stefano@openstack.org, markmc@redhat.com',
    description => 'The place to discuss legal matter, like choice of licenses',
    mailserver  => 'lists.openstack.org',
    name        => 'legal-discuss',
    password    => '1234',
    webserver   => 'lists.openstack.org',
}

  realize (
    User::Virtual::Localuser['oubiwann'],
    User::Virtual::Localuser['smaffulli'],
  )
}
