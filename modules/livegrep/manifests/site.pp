# == Define: site
#
define livegrep::site(
  $repos=[],
  $vhost_name="livegrep.${name}.org",
) {

  include apache

  apache::vhost::proxy { $vhost_name:
    port    => 80,
    dest    => 'http://localhost:8080',
  }

}
