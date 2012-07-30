class mediawiki::apache($site_hostname, $mediawiki_location) {
  package { ["apache2", "libapache2-mod-php5"]:
    ensure => latest;
  }
  #TODO: enable rewrite, expires, and ssl apache modules
  service { ["apache2"]:
    ensure => running,
    enable => true,
    require => [Package["apache2"]];
  }
  file {
    "/etc/apache2/sites-enabled/000-default":
      ensure => absent,
      require => [Package["apache2"]],
      notify => Service["apache2"];
    "/etc/apache2/sites-available/mediawiki":
      content => template("mediawiki/apache/mediawiki"),
      owner => root,
      group => root,
      mode => 444,
      require => [Package["apache2"]],
      notify => Service["apache2"];
    "/etc/apache2/sites-enabled/000-mediawiki":
      ensure => link,
      target => "/etc/apache2/sites-available/mediawiki",
      require => [Package["apache2"]],
      notify => Service["apache2"];
  }
}
