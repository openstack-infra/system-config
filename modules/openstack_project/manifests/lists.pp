# == Class: openstack_project::lists
#
class openstack_project::lists(
  $listadmins,
  $listpassword = ''
) {
  # Using openstack_project::template instead of openstack_project::server
  # because the exim config on this machine is almost certainly
  # going to be more complicated than normal.
  class { 'openstack_project::template':
    iptables_public_tcp_ports => [25, 80, 465],
  }

  $listdomain = 'lists.openstack.org'

  class { 'exim':
    sysadmin        => $listadmins,
    mailman_domains => [$listdomain],
  }

  class { 'mailman':
    vhost_name => $listdomain,
  }

  realize (
    User::Virtual::Localuser['oubiwann'],
    User::Virtual::Localuser['smaffulli'],
  )

  maillist { 'openstack-it':
    ensure      => present,
    admin       => 'stefano@openstack.org',
    password    => $listpassword,
    description => 'Discussioni su OpenStack in italiano',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

}
