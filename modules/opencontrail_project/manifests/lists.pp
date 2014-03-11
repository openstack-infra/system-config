# == Class: opencontrail_project::lists
#
class opencontrail_project::lists(
  $listadmins,
  $listpassword = ''
) {
  # Using opencontrail_project::template instead of opencontrail_project::server
  # because the exim config on this machine is almost certainly
  # going to be more complicated than normal.
  class { 'opencontrail_project::template':
    iptables_public_tcp_ports => [25, 80, 465],
  }

  $listdomain = 'lists.opencontrail.org'

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

  maillist { 'opencontrail-es':
    ensure      => present,
    admin       => 'flavio@redhat.com',
    password    => $listpassword,
    description => 'Lista de correo acerca de OpenContrail en español',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'opencontrail-fr':
    ensure      => present,
    admin       => 'erwan.gallen@cloudwatt.com',
    password    => $listpassword,
    description => 'List of the OpenContrail french user group',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'opencontrail-i18n':
    ensure      => present,
    admin       => 'guoyingc@cn.ibm.com',
    password    => $listpassword,
    description => 'List of the OpenContrail Internationalization team.',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'opencontrail-it':
    ensure      => present,
    admin       => 'stefano@opencontrail.org',
    password    => $listpassword,
    description => 'Discussioni su OpenContrail in italiano',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'opencontrail-travel-committee':
    ensure      => present,
    admin       => 'communitymngr@opencontrail.org',
    password    => $listpassword,
    description => 'Private discussions for the OpenContrail Travel Program Committee for Hong Kong Summit 2013.',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'opencontrail-personas':
    ensure      => present,
    admin       => 'pieter.c.kruithof-jr@hp.com',
    password    => $listpassword,
    description => 'A group of designers, researchers, developers, writers and users that are creating a set of personas for OpenContrail that are intended to help drive development around the needs of our users.',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'opencontrail-vi':
    ensure      => present,
    admin       => 'hang.tran@dtt.vn',
    password    => $listpassword,
    description => 'Discussions in Vietnamese - please add Vietnamese translation here',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'nov-2013-track-chairs':
    ensure      => present,
    admin       => 'claire@opencontrail.org',
    password    => $listpassword,
    description => 'Coordination of tracks at OpenContrail Summit April 2013',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'opencontrail-track-chairs':
    ensure      => present,
    admin       => 'claire@opencontrail.org',
    password    => $listpassword,
    description => 'Coordination of tracks at OpenContrail Summits',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'opencontrail-sos':
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
    description => 'Discussions of the OpenContrail Foundation Elections Committee',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'defcore-committee':
    ensure      => present,
    admin       => 'josh@opencontrail.org',
    password    => $listpassword,
    description => 'Discussions of the OpenContrail Foundation Core Definition Committee',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }


  maillist { 'ambassadors':
    ensure      => present,
    admin       => 'tom@opencontrail.org',
    password    => $listpassword,
    description => 'Private discussions between OpenContrail Ambassadors',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }
}
