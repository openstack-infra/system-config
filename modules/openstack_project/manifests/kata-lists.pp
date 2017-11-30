# == Class: openstack_project::kata-lists
#
class openstack_project::kata-lists(
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

  # Disable inactive admins
  user::virtual::disable { 'oubiwann': }
  user::virtual::disable { 'rockstar': }

  include bup
  bup::site { 'ord.rax':
    backup_user   => 'bup-lists',
    backup_server => 'backup01.ord.rax.ci.openstack.org',
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
}
