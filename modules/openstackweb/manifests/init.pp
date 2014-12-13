# == Class: openstackweb
#
# Installs dependencies of openstack web project deployment.
# This includes apache, php5, composer, and the source of
# openstackweb itself.
#
class openstackweb (
  $source = 'https://git.openstack.org/openstack-infra/openstackweb',
  $revision = 'master',
) {
  include apache

  package { 'php5':
    ensure => present,
  }

  package { 'wget':
    ensure => present,
  }

  # TODO (clarkb) install git archive of this repo in /var/www
  # or somewhere else that is not a git repo and use that as proper
  # install location.
  vcsrepo { '/opt/openstackweb':
    ensure   => present,
    provider => git,
    source   => $source,
    revision => $revision,
    require  => Package['git'],
  }

  # TODO(clarkb) install composer more sanely
  exec { 'download_composer':
    command => '/usr/bin/wget https://getcomposer.org/installer -O composer.installer',
    cwd     => '/opt/openstackweb',
    creates => '/opt/openstackweb/composer.installer',
    require => Package['wget'],
  }
  exec { 'install_composer':
    command => '/usr/bin/php composer.installer',
    cwd     => '/opt/openstackweb',
    creates => '/opt/openstackweb/composer.phar',
    require => [
      Exec['download_composer'],
      Package['php5'],
    ],
  }
}
