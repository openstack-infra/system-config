class mediawiki($role, $site_hostname, $mediawiki_location='') {
  if ($role == "app" or $role == "all") {
    include mediawiki::php,
            mediawiki::app

    class { 'mediawiki::apache':
      site_hostname => $site_hostname,
      mediawiki_location => $mediawiki_location;
    }
  }
  if ($role == "image-scaler" or $role == "all") {
    include mediawiki::"image-scaler",
            mediawiki::php,
            mediawiki::app
  }
  if ($role == "search" or $role == "all") {
    include mediawiki::search
  }
}
