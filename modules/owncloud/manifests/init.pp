# Class owncloud
#
class owncloud (
) {
  include apache

  # has to be version 5.0.4debian-0ubuntu1~ubuntu12.04
  package { 'owncloud' :
    ensure => present,
  }

  file { '/etc/owncloud/config.php' :
    ensure => present,
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0640',
    content => template('owncloud/config.php'),
  }
}
