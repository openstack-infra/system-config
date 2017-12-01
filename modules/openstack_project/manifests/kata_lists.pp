# == Class: openstack_project::kata_lists
#
class openstack_project::kata_lists(
  $listadmins,
  $listpassword = ''
) {
  $listdomain = 'lists.katacontainers.io'

  class { 'exim':
    sysadmins                => $listadmins,
    queue_interval           => '1m',
    queue_run_max            => '50',
    mailman_domains          => [$listdomain],
    smtp_accept_max          => '100',
    smtp_accept_max_per_host => '10',
  }

  class { 'mailman':
    vhost_name => $listdomain,
  }

  realize (
    User::Virtual::Localuser['jbryce'],
  )

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
}
