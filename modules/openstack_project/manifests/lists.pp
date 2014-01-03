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
    queue_interval  => '1m',
    queue_run_max   => '50',
    mailman_domains => [$listdomain],
  }

  class { 'mailman':
    vhost_name => $listdomain,
  }

  realize (
    User::Virtual::Localuser['oubiwann'],
    User::Virtual::Localuser['rockstar'],
    User::Virtual::Localuser['smaffulli'],
  )

  maillist { 'openstack-es':
    ensure      => present,
    admin       => 'flavio@redhat.com',
    password    => $listpassword,
    description => 'Lista de correo acerca de OpenStack en español',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'openstack-fr':
    ensure      => present,
    admin       => 'erwan.gallen@cloudwatt.com',
    password    => $listpassword,
    description => 'List of the OpenStack french user group',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'openstack-i18n':
    ensure      => present,
    admin       => 'guoyingc@cn.ibm.com',
    password    => $listpassword,
    description => 'List of the OpenStack Internationalization team.',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'openstack-it':
    ensure      => present,
    admin       => 'stefano@openstack.org',
    password    => $listpassword,
    description => 'Discussioni su OpenStack in italiano',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'openstack-travel-committee':
    ensure      => present,
    admin       => 'communitymngr@openstack.org',
    password    => $listpassword,
    description => 'Private discussions for the OpenStack Travel Program Committee for Hong Kong Summit 2013.',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'openstack-personas':
    ensure      => present,
    admin       => 'pieter.c.kruithof-jr@hp.com',
    password    => $listpassword,
    description => 'A group of designers, researchers, developers, writers and users that are creating a set of personas for OpenStack that are intended to help drive development around the needs of our users.',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'openstack-vi':
    ensure      => present,
    admin       => 'hang.tran@dtt.vn',
    password    => $listpassword,
    description => 'Discussions in Vietnamese - please add Vietnamese translation here',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'nov-2013-track-chairs':
    ensure      => present,
    admin       => 'claire@openstack.org',
    password    => $listpassword,
    description => 'Coordination of tracks at OpenStack Summit April 2013',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'openstack-sos':
    ensure      => present,
    admin       => 'dms@danplanet.com',
    password    => $listpassword,
    description => 'Coordination of activities for Significant Others at Summits',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'elections-committee':
    ensure      => present,
    admin       => 'markmc@redhat.com',
    password    => $listpassword,
    description => 'Discussions of the OpenStack Foundation Elections Committee',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'defcore-committee':
    ensure      => present,
    admin       => 'josh@openstack.org',
    password    => $listpassword,
    description => 'Discussions of the OpenStack Foundation Core Definition Committee',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }
}
