# == Class: openstack_project::lists
#
class openstack_project::lists(
  $listadmins,
  $listpassword = ''
) {
  $listdomain = 'lists.openstack.org'

  class { 'exim':
    sysadmins       => $listadmins,
    queue_interval  => '1m',
    queue_run_max   => '50',
    mailman_domains => [$listdomain],
  }

  class { 'mailman':
    vhost_name => $listdomain,
  }

  realize (
    User::Virtual::Localuser['smaffulli'],
  )

  # Disable inactive admins
  user::virtual::disable { 'oubiwann': }
  user::virtual::disable { 'rockstar': }

  include bup
  bup::site { 'rs-ord':
    backup_user   => 'bup-lists',
    backup_server => 'ci-backup-rs-ord.openstack.org',
  }

  Maillist {
    provider    => 'noaliasmailman',
  }

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
    admin       => 'erwan@erwan.com',
    password    => $listpassword,
    description => 'List of the OpenStack french user group',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'openstack-de':
    ensure      => present,
    admin       => 'christian@berendt.io',
    password    => $listpassword,
    description => 'List for German-speaking OpenStack users',
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

  maillist { 'openstack-i18n-de':
    ensure      => present,
    admin       => 'robert.simai@suse.com',
    password    => $listpassword,
    description => 'List of the German OpenStack Internationalization team.',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'openstack-ir':
    ensure      => present,
    admin       => 'Roozbeh.Shafiee@Gmail.Com',
    password    => $listpassword,
    description => 'OpenStack IRAN Community Discussions in Persian/Farsi',
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

  maillist { 'openstack-el':
    ensure      => present,
    admin       => 'aparathyras@stackmasters.eu',
    password    => $listpassword,
    description => 'List of the OpenStack Greek User Group',
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

  maillist { 'openstack-tw':
    ensure      => present,
    admin       => 'macjacktw@hotmail.com',
    password    => $listpassword,
    description => 'OpenStack Taiwan User Group 臺灣使用者郵件群組)',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'openstack-ko':
    ensure      => present,
    admin       => 'ianyrchoi@gmail.com',
    password    => $listpassword,
    description => 'OpenStack Korea Community Discussions in Korean (오픈스택 한국 커뮤니티 메일링리스트)',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'openstack-ru':
    ensure      => present,
    admin       => 'ilyaalekseyev@acm.org',
    password    => $listpassword,
    description => 'Рассылка для обсуждения OpenStack на русском',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'openstack-zh':
    ensure      => present,
    admin       => 'yeluaiesec@gmail.com',
    password    => $listpassword,
    description => 'OpenStack社区中文讨论群组',
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

  maillist { 'openstack-track-chairs':
    ensure      => present,
    admin       => 'claire@openstack.org',
    password    => $listpassword,
    description => 'Coordination of tracks at OpenStack Summits',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'summitsponsors':
    ensure      => present,
    admin       => 'claire@openstack.org',
    password    => $listpassword,
    description => 'Coordination among OpenStack Summit event sponsors',
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

  maillist { 'interop-wg':
    ensure      => present,
    admin       => 'chris@openstack.org',
    password    => $listpassword,
    description => 'Discussions of the OpenStack Foundation Board Interoperability Working Group',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'ambassadors':
    ensure      => present,
    admin       => 'tom@openstack.org',
    password    => $listpassword,
    description => 'Private discussions between OpenStack Ambassadors',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'openstack-content':
    ensure      => present,
    admin       => 'margie@openstack.org',
    password    => $listpassword,
    description => 'Discussions of the OpenStack Content team',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'superuser':
    ensure      => present,
    admin       => 'lauren@openstack.org',
    password    => $listpassword,
    description => 'Discussions for Superuser editorial advisors to collaborate, and for readers to be able to contact the editorial team to make suggestions, provide feedback',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'admin-cert-wg':
    ensure      => present,
    admin       => 'heidi@openstack.org',
    password    => $listpassword,
    description => 'Collaboration workspace for members of the Certified OpenStack Administrator Working Group of the User Commitee/Board.',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'openstack-api-consumers':
    ensure      => present,
    admin       => 'mordred@inaugust.com',
    password    => $listpassword,
    description => 'Discussions around consuming the OpenStack REST APIs and development of API-consuming SDKs and frameworks',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'openstack-sigs':
    ensure      => present,
    admin       => 'thierry@openstack.org',
    password    => $listpassword,
    description => 'OpenStack SIGs discussions, gathering users, operators and developers of OpenStack into common groups.',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'product-wg':
    ensure      => present,
    admin       => 'stefano@openstack.org',
    password    => $listpassword,
    description => 'Collaboration workspace for OpenStack-related Product Managers working group.',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'tax-affairs':
    ensure      => present,
    admin       => 'seanroberts66@gmail.com',
    password    => $listpassword,
    description => 'board committee focused on tax issues.',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'third-party-announce':
    ensure      => present,
    admin       => 'anteaya@anteaya.info',
    password    => $listpassword,
    description => 'Announcements for third party CI operators.',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'women-of-openstack':
    ensure      => present,
    admin       => 'claire@openstack.org',
    password    => $listpassword,
    description => 'Women of OpenStack discussion list.',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'openstack-internships':
    ensure      => present,
    admin       => 'stefano@openstack.org',
    password    => $listpassword,
    description => 'List to coordinate mentors and interns of OpenStack programs.',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'foundation-testing-standards':
    ensure      => present,
    admin       => 'seanroberts66@gmail.com',
    password    => $listpassword,
    description => 'OpenStack Foundation test standards (for humans, not
    drivers) working group list.',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'analyst-relations':
    ensure      => present,
    admin       => 'lauren@openstack.org',
    password    => $listpassword,
    description => 'Coordination of Analyst Relations Working Group.',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'app-catalog-admin':
    ensure      => present,
    admin       => 'doc@aedo.net',
    password    => $listpassword,
    description => 'Coordinate admin details for OpenStack Community App Catalog.',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'openstack-i18n-fr':
    ensure      => present,
    admin       => 'jftalta@gmail.com',
    password    => $listpassword,
    description => 'List of the OpenStack Internationalization team, french local group.',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'release-job-failures':
    ensure      => present,
    admin       => 'doug@doughellmann.com',
    password    => $listpassword,
    description => 'Notification messages for failures from release-related build jobs.',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'embargo-notice':
    ensure      => present,
    admin       => 'jeremy@openstack.org',
    password    => $listpassword,
    description => 'Announcements to stakeholders for embargoed security vulnerabilities.',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'release-announce':
    ensure      => present,
    admin       => 'thierry@openstack.org',
    password    => $listpassword,
    description => 'Announcement of official OpenStack releases.',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }
}
