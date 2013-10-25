# Class owncloud
#
class owncloud (
  $sysadmins = '',
  $mysql_password = '',
) {
  include apache

  # has to be version 5.x
  package { 'owncloud' :
    ensure => present,
  }

  file { '/etc/owncloud/config.php' :
    ensure  => present,
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0640',
    content => template('owncloud/config.php.erb'),
    notify  => Service['httpd'],
  }
}
