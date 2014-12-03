# == Class: openstack_project::lists
#
class openstack_project::lists(
  $admin_users = [
    'oubiwann',
    'rockstar',
    'smaffulli',
  ],
  $listadmins,
  $listpassword = '',
  $listdomain = 'lists.openstack.org',
  $mailing_lists = {
    'openstack-es' => { 'admin' => 'flavio@redhat.com', 'description' => 'Lista de correo acerca de OpenStack en español' },
    'openstack-fr' => { 'admin' => 'erwan.gallen@cloudwatt.com', 'description' => 'List of the OpenStack french user group' },
    'openstack-i18n' => { 'admin' => 'guoyingc@cn.ibm.com', 'description' => 'List of the OpenStack Internationalization team.' },
    'openstack-ir' => { 'admin' => 'Roozbeh.Shafiee@Gmail.Com', 'description' => 'OpenStack IRAN Community Discussions in Persian/Farsi' },
    'openstack-it' => { 'admin' => 'stefano@openstack.org', 'description' => 'Discussioni su OpenStack in italiano' },
    'openstack-el' => { 'admin' => 'aparathyras@stackmasters.eu', 'description' => 'List of the OpenStack Greek User Group' },
    'openstack-travel-committee' => { 'admin' => 'communitymngr@openstack.org', 'description' => 'Private discussions for the OpenStack Travel Program Committee for Hong Kong Summit 2013.' },
    'openstack-personas' => { 'admin' => 'pieter.c.kruithof-jr@hp.com', 'description' => 'A group of designers, researchers, developers, writers and users that are creating a set of personas for OpenStack that are intended to help drive development around the needs of our users.' },
    'openstack-vi' => { 'admin' => 'hang.tran@dtt.vn', 'description' => 'Discussions in Vietnamese - please add Vietnamese translation here' },
    'nov-2013-track-chairs' => { 'admin' => 'claire@openstack.org', 'description' => 'Coordination of tracks at OpenStack Summit April 2013' },
    'openstack-track-chairs' => { 'admin' => 'claire@openstack.org', 'description' => 'Coordination of tracks at OpenStack Summits' },
    'openstack-sos' => { 'admin' => 'dms@danplanet.com', 'description' => 'Coordination of activities for Significant Others at Summits' },
    'elections-committee' => { 'admin' => 'markmc@redhat.com', 'description' => 'Discussions of the OpenStack Foundation Elections Committee' },
    'defcore-committee' => { 'admin' => 'josh@openstack.org', 'description' => 'Discussions of the OpenStack Foundation Core Definition Committee' },
    'ambassadors' => { 'admin' => 'tom@openstack.org', 'description' => 'Private discussions between OpenStack Ambassadors' },
    'openstack-content' => { 'admin' => 'margie@openstack.org', 'description' => 'Discussions of the OpenStack Content team' },
    'superuser' => { 'admin' => 'lauren@openstack.org', 'description' => 'Discussions for Superuser editorial advisors to collaborate, and for readers to be able to contact the editorial team to make suggestions, provide feedback' },
    'enterprise-wg' => { 'admin' => 'carol.l.barrett@intel.com', 'description' => 'Collaboration workspace for members of the Win The Enterprise Working Group of the User Commitee/Board.' },
    'product-wg' => { 'admin' => 'stefano@openstack.org', 'description' => 'Collaboration workspace for OpenStack-related Product Managers working group.' },
    'tax-affairs' => { 'admin' => 'seanroberts66@gmail.com', 'description' => 'board committee focused on tax issues.' },
    'third-party-announce' => { 'admin' => 'anteaya@anteaya.info', 'description' => 'Announcements for third party CI operators.' },
    'third-party-requests' => { 'admin' => 'anteaya@anteaya.info', 'description' => 'Third party system account requests.' },
    'women-of-openstack' => { 'admin' => 'claire@openstack.org', 'description' => 'Women of OpenStack discussion list.' },
  },
) {
  # Using openstack_project::template instead of openstack_project::server
  # because the exim config on this machine is almost certainly
  # going to be more complicated than normal.
  class { 'openstack_project::template':
    iptables_public_tcp_ports => [25, 80, 465],
  }

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
    User::Virtual::Localuser[$admin_users],
  )

  create_resources(openstack_project::add_mailing_list,$mailing_lists)

}
