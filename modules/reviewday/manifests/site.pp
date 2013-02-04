# == Define: reviewday
#
define reviewday::site(
  $git_url,
) {
  include apache
  include remove_nginx

  vcsrepo { "/var/lib/reviewday/reviewday":
    ensure   => present,
    provider => git,
    source   => $git_url,
  }
  file { '/var/lib/reviewday/.ssh/config':
    ensure  => present,
    source  => 'puppet:///modules/reviewday/ssh_config',
    owner   => reviewday,
    group   => reviewday,
    mode    => '0644',
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
