# Class: mediawiki
#
class mediawiki(
  $role = 'UNSET',
  $site_hostname = '',
  $mediawiki_location = ''
) {

  include mediawiki::params

  $role_real = $role ? {
    'UNSET' => $::mediawiki::params::server,
    default => $role,
  }

  if ($role_real == 'app' or $role_real == 'all') {
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
  if ($role_real == 'image-scaler' or $role_real == 'all') {
    include mediawiki::image_scaler
    include mediawiki::php
    include mediawiki::app
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
