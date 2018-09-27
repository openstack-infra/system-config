# == Class: openstack_project::kata_lists
#
class openstack_project::kata_lists(
  $listpassword = ''
) {

  $listdomain = 'lists.katacontainers.io'

  class { 'mailman':
    vhost_name => $listdomain,
  }

  Maillist {
    provider    => 'noaliasmailman',
  }

  maillist { 'kata-dev':
    ensure      => present,
    admin       => 'jonathan@openstack.org',
    password    => $listpassword,
    description => 'Kata Containers Development Mailing List (not for usage questions)',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'kata-hypervisor':
    ensure      => present,
    admin       => 'jonathan@openstack.org',
    password    => $listpassword,
    description => 'Discussion of security and virtualization targeted at container use cases',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

  maillist { 'embargo-notice':
    ensure      => present,
    admin       => 'jonathan@openstack.org',
    password    => $listpassword,
    description => 'Announcements of embargoed notices for the Kata Containers project',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }
}
