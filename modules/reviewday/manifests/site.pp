# == Define: reviewday
#
define reviewday::site(
  $git_url,
) {
  include apache
  include remove_nginx

  vcsrepo { "/var/lib/reviewday/${name}":
    ensure   => present,
    provider => git,
    source   => $git_url,
  }
  file { '/var/lib/reviewday/.ssh/config':
    ensure  => present,
    source  => 'puppet:///modules/reviewday/config',
    owner   => reviewday,
    group   => reviewday,
    mode    => '0644',
    require => Class['etherpad_lite'],
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
