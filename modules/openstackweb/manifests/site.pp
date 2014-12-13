# == Class: openstackweb::site
#
# Installs and configures the openstack web project.
# Note this does not manage the databases for which info is
# passed in. The expectation is that the DB is managed externally
# either via a cloud db or even another puppet manifest.
#
class openstackweb::site (
  $dbpasswd,
  $dbuser = 'www',
  $dbname = 'www',
  $dbhost = 'localhost',
  $vhost_name = $fqdn,
  $environment_type = 'development',
) {
  exec { 'install-openstackweb':
    command     => '/usr/bin/php composer.phar install',
    cwd         => '/opt/openstackweb',
    environment => 'HOME=/tmp',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/openstackweb'],
  }

  exec { 'openstackweb-optimize':
    command     => '/usr/bin/php composer.phar dump-autoload --optimize',
    cwd         => '/opt/openstackweb',
    environment => 'HOME=/tmp',
    refreshonly => true,
    subscribe   => Exec['install-openstackweb'],
  }

  exec { 'TODO-remove-this-exec-because-why':
    command     => '/bin/chmod 777 -R  vendor/ezyang/htmlpurifier/library/HTMLPurifier/DefinitionCache/Serializer',
    cwd         => '/opt/openstackweb',
    refreshonly => true,
    subscribe   => Exec['openstackweb-optimize'],
  }

  # TODO(clarkb) don't use git repo as docroot
  apache::vhost { $vhost_name:
    port     => 443,
    docroot  => '/opt/openstackweb',
    priority => '50',
    template => 'openstackweb/openstackweb.vhost.erb',
    ssl      => true,
    require  => Exec['TODO-remove-this-exec-because-why'],
  }

  file { '/opt/openstackweb/_ss_environment.php':
    ensure => present,
    content => template('openstackweb/_ss_environment.php.erb'),
    replace => true,
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0600',
    require  => Exec['TODO-remove-this-exec-because-why'],
  }

  file { '/opt/openstackweb/.htaccess':
    ensure => present,
    content => template('openstackweb/htaccess.erb'),
    replace => true,
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0600',
    require  => Exec['TODO-remove-this-exec-because-why'],
  }

  file { '/opt/openstackweb/robots.txt':
    ensure => present,
    source => 'puppet:///modules/openstackweb/robots.txt',
    replace => true,
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0600',
    require  => Exec['TODO-remove-this-exec-because-why'],
  }
}
