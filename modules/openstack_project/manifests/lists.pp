# == Class: openstack_project::lists
#
class openstack_project::lists(
  $listpassword = ''
) {

  class { 'mailman':
    multihost => true,
  }

  # Disable inactive admins
  user::virtual::disable { 'oubiwann': }
  user::virtual::disable { 'rockstar': }

  include bup
  bup::site { 'ord.rax':
    backup_user   => 'bup-lists',
    backup_server => 'backup01.ord.rax.ci.openstack.org',
  }

  # Begin user servicable parts

  mailman::site { 'openstack':
    default_email_host => 'lists.openstack.org',
    default_url_host   => 'lists.openstack.org',
    # en has customized templates, don't install it here
    install_languages  => ['de', 'fr', 'it', 'ko', 'ru', 'vi', 'zh_TW'],
  }

  file { '/srv/mailman/openstack/templates/en':
    ensure  => directory,
    owner   => 'root',
    group   => 'list',
    mode    => '0644',
    recurse => true,
    require => File['/srv/mailman/openstack/templates'],
    source  => 'puppet:///modules/openstack_project/mailman/html-templates-en',
  }

  mailman::site { 'zuul':
    default_email_host => 'lists.zuul-ci.org',
    default_url_host   => 'lists.zuul-ci.org',
  }

  mailman::site { 'airship':
    default_email_host => 'lists.airshipit.org',
    default_url_host   => 'lists.airshipit.org',
  }

  mailman::site { 'starlingx':
    default_email_host => 'lists.starlingx.io',
    default_url_host   => 'lists.starlingx.io',
  }

  mailman::site { 'opendev':
    default_email_host => 'lists.opendev.org',
    default_url_host   => 'lists.opendev.org',
  }

  # Add new mailing lists below this line

  mailman_list { 'mailman@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'nobody@openstack.org',
    password    => $listpassword,
    description => 'The mailman site list',
  }

  mailman_list { 'openstack-es@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'flavio@redhat.com',
    password    => $listpassword,
    description => 'Lista de correo acerca de OpenStack en español',
  }

  mailman_list { 'openstack-fr@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'erwan@erwan.com',
    password    => $listpassword,
    description => 'List of the OpenStack french user group',
  }

  mailman_list { 'openstack-de@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'christian@berendt.io',
    password    => $listpassword,
    description => 'List for German-speaking OpenStack users',
  }

  mailman_list { 'openstack-i18n@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'guoyingc@cn.ibm.com',
    password    => $listpassword,
    description => 'List of the OpenStack Internationalization team.',
  }

  mailman_list { 'openstack-i18n-de@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'robert.simai@suse.com',
    password    => $listpassword,
    description => 'List of the German OpenStack Internationalization team.',
  }

  mailman_list { 'openstack-ir@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'Roozbeh.Shafiee@Gmail.Com',
    password    => $listpassword,
    description => 'OpenStack IRAN Community Discussions in Persian/Farsi',
  }

  mailman_list { 'openstack-it@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'stefano@openstack.org',
    password    => $listpassword,
    description => 'Discussioni su OpenStack in italiano',
  }

  mailman_list { 'openstack-el@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'aparathyras@stackmasters.eu',
    password    => $listpassword,
    description => 'List of the OpenStack Greek User Group',
  }

  mailman_list { 'openstack-travel-committee@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'communitymngr@openstack.org',
    password    => $listpassword,
    description => 'Private discussions for the OpenStack Travel Program Committee for Hong Kong Summit 2013.',
  }

  mailman_list { 'openstack-personas@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'pieter.c.kruithof-jr@hp.com',
    password    => $listpassword,
    description => 'A group of designers, researchers, developers, writers and users that are creating a set of personas for OpenStack that are intended to help drive development around the needs of our users.',
  }

  mailman_list { 'openstack-vi@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'hang.tran@dtt.vn',
    password    => $listpassword,
    description => 'Discussions in Vietnamese - please add Vietnamese translation here',
  }

  mailman_list { 'openstack-tw@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'macjacktw@hotmail.com',
    password    => $listpassword,
    description => 'OpenStack Taiwan User Group 臺灣使用者郵件群組)',
  }

  mailman_list { 'openstack-ko@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'ianyrchoi@gmail.com',
    password    => $listpassword,
    description => 'OpenStack Korea Community Discussions in Korean (오픈스택 한국 커뮤니티 메일링리스트)',
  }

  mailman_list { 'openstack-ru@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'ilyaalekseyev@acm.org',
    password    => $listpassword,
    description => 'Рассылка для обсуждения OpenStack на русском',
  }

  mailman_list { 'openstack-zh@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'yeluaiesec@gmail.com',
    password    => $listpassword,
    description => 'OpenStack社区中文讨论群组',
  }

  mailman_list { 'nov-2013-track-chairs@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'claire@openstack.org',
    password    => $listpassword,
    description => 'Coordination of tracks at OpenStack Summit April 2013',
  }

  mailman_list { 'openstack-track-chairs@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'claire@openstack.org',
    password    => $listpassword,
    description => 'Coordination of tracks at OpenStack Summits',
  }

  mailman_list { 'summitsponsors@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'claire@openstack.org',
    password    => $listpassword,
    description => 'Coordination among OpenStack Summit event sponsors',
  }

  mailman_list { 'openstack-sos@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'dms@danplanet.com',
    password    => $listpassword,
    description => 'Coordination of activities for Significant Others at Summits',
  }

  mailman_list { 'elections-committee@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'markmc@redhat.com',
    password    => $listpassword,
    description => 'Discussions of the OpenStack Foundation Elections Committee',
  }

  mailman_list { 'defcore-committee@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'josh@openstack.org',
    password    => $listpassword,
    description => 'Discussions of the OpenStack Foundation Core Definition Committee',
  }

  mailman_list { 'ambassadors@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'tom@openstack.org',
    password    => $listpassword,
    description => 'Private discussions between OpenStack Ambassadors',
  }

  mailman_list { 'openstack-content@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'margie@openstack.org',
    password    => $listpassword,
    description => 'Discussions of the OpenStack Content team',
  }

  mailman_list { 'superuser@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'lauren@openstack.org',
    password    => $listpassword,
    description => 'Discussions for Superuser editorial advisors to collaborate, and for readers to be able to contact the editorial team to make suggestions, provide feedback',
  }

  mailman_list { 'admin-cert-wg@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'heidi@openstack.org',
    password    => $listpassword,
    description => 'Collaboration workspace for members of the Certified OpenStack Administrator Working Group of the User Commitee/Board.',
  }

  mailman_list { 'openstack-api-consumers@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'mordred@inaugust.com',
    password    => $listpassword,
    description => 'Discussions around consuming the OpenStack REST APIs and development of API-consuming SDKs and frameworks',
  }

  mailman_list { 'enterprise-wg@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'carol.l.barrett@intel.com',
    password    => $listpassword,
    description => 'Collaboration workspace for members of the Win The Enterprise Working Group of the User Commitee/Board.',
  }

  mailman_list { 'product-wg@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'stefano@openstack.org',
    password    => $listpassword,
    description => 'Collaboration workspace for OpenStack-related Product Managers working group.',
  }

  mailman_list { 'tax-affairs@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'seanroberts66@gmail.com',
    password    => $listpassword,
    description => 'board committee focused on tax issues.',
  }

  mailman_list { 'third-party-announce@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'anteaya@anteaya.info',
    password    => $listpassword,
    description => 'Announcements for third party CI operators.',
  }

  mailman_list { 'women-of-openstack@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'claire@openstack.org',
    password    => $listpassword,
    description => 'Women of OpenStack discussion list.',
  }

  mailman_list { 'foundation-testing-standards@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'seanroberts66@gmail.com',
    password    => $listpassword,
    description => 'OpenStack Foundation test standards (for humans, not
    drivers) working group list.',
  }

  mailman_list { 'analyst-relations@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'lauren@openstack.org',
    password    => $listpassword,
    description => 'Coordination of Analyst Relations Working Group.',
  }

  mailman_list { 'app-catalog-admin@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'doc@aedo.net',
    password    => $listpassword,
    description => 'Coordinate admin details for OpenStack Community App Catalog.',
  }

  mailman_list { 'openstack-i18n-fr@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'jftalta@gmail.com',
    password    => $listpassword,
    description => 'List of the OpenStack Internationalization team, french local group.',
  }

  mailman_list { 'release-job-failures@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'doug@doughellmann.com',
    password    => $listpassword,
    description => 'Notification messages for failures from release-related build jobs.',
  }

  mailman_list { 'embargo-notice@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'jeremy@openstack.org',
    password    => $listpassword,
    description => 'Announcements to stakeholders for embargoed security vulnerabilities.',
  }

  mailman_list { 'release-announce@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'thierry@openstack.org',
    password    => $listpassword,
    description => 'Announcement of official OpenStack releases.',
  }

  mailman_list { 'edge-computing@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'claire@openstack.org',
    password    => $listpassword,
    description => 'Organizing efforts around the edge-computing focus area.',
  }

  mailman_list { 'openstack-mentoring@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'amy@demarco.com',
    password    => $listpassword,
    description => 'List to coordinate interactions between mentors and mentees of the OpenStack mentoring program. Also for questions about the mentoring program (i.e. how to get involved, how it works, etc.',
  }

  mailman_list { 'mailman@zuul':
    require     => Mailman::Site['zuul'],
    ensure      => present,
    admin       => 'nobody@openstack.org',
    password    => $listpassword,
    description => 'The mailman site list',
  }

  mailman_list { 'zuul-announce@zuul':
    require     => Mailman::Site['zuul'],
    ensure      => present,
    admin       => 'corvus@inaugust.com',
    password    => $listpassword,
    description => 'Announcements of Zuul releases and other important information.',
  }

  mailman_list { 'zuul-discuss@zuul':
    require     => Mailman::Site['zuul'],
    ensure      => present,
    admin       => 'corvus@inaugust.com',
    password    => $listpassword,
    description => 'Discussion of Zuul usage and development.',
  }

  mailman_list { 'mailman@airship':
    require     => Mailman::Site['airship'],
    ensure      => present,
    admin       => 'nobody@openstack.org',
    password    => $listpassword,
    description => 'The mailman site list',
  }

  mailman_list { 'airship-announce@airship':
    require     => Mailman::Site['airship'],
    ensure      => present,
    admin       => 'jonathan@openstack.org',
    password    => $listpassword,
    description => 'Announcements of Airship releases and other important information.',
  }

  mailman_list { 'airship-discuss@airship':
    require     => Mailman::Site['airship'],
    ensure      => present,
    admin       => 'jonathan@openstack.org',
    password    => $listpassword,
    description => 'Discussion of Airship usage and development.',
  }

  mailman_list { 'mailman@starlingx':
    require     => Mailman::Site['starlingx'],
    ensure      => present,
    admin       => 'nobody@openstack.org',
    password    => $listpassword,
    description => 'The mailman site list',
  }

  mailman_list { 'starlingx-announce@starlingx':
    require     => Mailman::Site['starlingx'],
    ensure      => present,
    admin       => 'jonathan@openstack.org',
    password    => $listpassword,
    description => 'Announcements of StarlingX releases and other important information.',
  }

  mailman_list { 'starlingx-discuss@starlingx':
    require     => Mailman::Site['starlingx'],
    ensure      => present,
    admin       => 'jonathan@openstack.org',
    password    => $listpassword,
    description => 'Discussion of StarlingX usage and development.',
  }

  mailman_list { 'openstack-discuss@openstack':
    require     => Mailman::Site['openstack'],
    ensure      => present,
    admin       => 'fungi@yuggoth.org',
    password    => $listpassword,
    description => 'Discussion of OpenStack usage and development.',
  }

  mailman_list { 'mailman@opendev':
    require     => Mailman::Site['opendev'],
    ensure      => present,
    admin       => 'nobody@openstack.org',
    password    => $listpassword,
    description => 'The mailman site list',
  }

  mailman_list { 'rust-vmm@opendev':
    require     => Mailman::Site['opendev'],
    ensure      => present,
    admin       => 'claire@openstack.org',
    password    => $listpassword,
    description => 'Collaborating on Rust-based virtual machine monitors.',
  }

  mailman_list { 'rustyk8s@opendev':
    require     => Mailman::Site['opendev'],
    ensure      => present,
    admin       => 'allison@lohutok.net',
    password    => $listpassword,
    description => 'Collaborating on Rust-based Kubernetes API.',
  }
}
