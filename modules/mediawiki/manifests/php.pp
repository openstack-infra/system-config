class mediawiki::php {
  package { ["php5", "php5-cli", "php5-mysql", "php-apc", "php5-intl"]:
    ensure => latest;
  }
  # TODO: apc configuration
}
