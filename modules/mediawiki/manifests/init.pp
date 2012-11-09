# Class: mediawiki
#
class mediawiki(
  $role = '',
  $site_hostname = '',
  $mediawiki_location = ''
) {

  if ($role == 'app' or $role == 'all') {
    require apache::dev
    include apache
    include mediawiki::php
    include mediawiki::app

    package { 'libapache2-mod-php5':
      ensure => present,
    }

    apache::vhost { $site_hostname:
      port     => 443,
      docroot  => 'MEANINGLESS ARGUMENT',
      priority => '50',
      template => 'mediawiki/apache/mediawiki.erb',
      ssl      => true,
    }
    a2mod { 'rewrite':
      ensure => present,
    }
    a2mod { 'expires':
      ensure => present,
    }
  }
  if ($role == 'image-scaler' or $role == 'all') {
    include mediawiki::image_scaler
    include mediawiki::php
    include mediawiki::app
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
