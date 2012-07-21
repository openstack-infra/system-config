$sysadmins = $openstack_project::sysadmins

class openstack_project::lists {
  # Using openstack_project::template instead of openstack_project::server
  # because the exim config on this machine is almost certainly
  # going to be more complicated than normal.
  class { 'openstack_project::template':
    iptables_public_tcp_ports => [25, 80, 465]
  }

  $sysadmins += ['duncan@dreamhost.com']
  class { 'exim':
    sysadmin => $sysadmins,
    mailman_domains => ['lists.openstack.org'],
  }

  class { 'mailman':
    mailman_host => 'lists.openstack.org'
  }

  realize (
    User::Virtual::Localuser["oubiwann"],
  )
}
