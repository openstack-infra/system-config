define reviewday::site(
  $git_url,
) {
  include apache
  include remove_nginx

  user { 'reviewday':
    ensure     => present,
    home       => '/home/reviewday',
    shell      => '/bin/bash',
    gid        => 'reviewday',
    managehome => true,
    require    => Group['reviewday'],
  }

  vcsrepo { "/home/reviewday/${name}":
    ensure   => present,
    provider => git,
    source   => $git_url,
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
