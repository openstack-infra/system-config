# == Class: openstack_project::status
#
class openstack_project::status (
  $gerrit_host,
  $gerrit_ssh_host_key,
  $reviewday_ssh_public_key = '',
  $reviewday_ssh_private_key = '',
  $recheck_ssh_public_key,
  $recheck_ssh_private_key,
  $recheck_bot_passwd,
  $recheck_bot_nick,
  $status_base_url = 'http://status.openstack.org',
  $status_title = 'OpenStack',
  $graphite_render_url = 'http://graphite.openstack.org/render/',
  $jenkins_gitfullname = 'OpenStack Jenkins',
  $jenkins_gitemail = 'jenkins@openstack.org',
  $openstack_health_api_endpoint = 'http://health.openstack.org',
) {

  include openstack_project
  class { 'jenkins::jenkinsuser':
    ssh_key => $openstack_project::jenkins_ssh_key,
    gitfullname => $jenkins_gitfullname,
    gitemail    => $jenkins_gitemail,
  }

  include ::httpd

  if ! defined(Httpd::Mod['rewrite']) {
    httpd::mod { 'rewrite':
        ensure => present,
    }
  }

  if ! defined(Httpd::Mod['proxy']) {
    httpd::mod { 'proxy':
        ensure => present,
    }
  }

  if ! defined(Httpd::Mod['proxy_http']) {
    httpd::mod { 'proxy_http':
        ensure => present,
    }
  }

  file { '/srv/static':
    ensure => directory,
  }

  ###########################################################
  # Status - Index

  ::httpd::vhost { 'status.openstack.org':
    port     => 80,
    priority => '50',
    docroot  => '/srv/static/status',
    template => 'openstack_project/status.vhost.erb',
    require  => File['/srv/static/status'],
  }

  file { '/srv/static/status':
    ensure => directory,
  }

  package { 'libjs-jquery':
    ensure => present,
  }

  package { 'yui-compressor':
    ensure => present,
  }

  file { '/srv/static/status/index.html':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/status/index.html',
    require => File['/srv/static/status'],
  }

  file { '/srv/static/status/favicon.ico':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/status/favicon.ico',
    require => File['/srv/static/status'],
  }

  file { '/srv/static/status/common.js':
    ensure  => present,
    content => template('openstack_project/status/common.js.erb'),
    require => File['/srv/static/status'],
    replace => true,
  }

  file { '/srv/static/status/jquery.min.js':
    ensure  => link,
    target  => '/usr/share/javascript/jquery/jquery.min.js',
    require => [File['/srv/static/status'],
                Package['libjs-jquery']],
  }

  vcsrepo { '/opt/jquery-visibility':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://github.com/mathiasbynens/jquery-visibility.git',
  }

  exec { 'install_jquery-visibility' :
    command     => 'yui-compressor -o /srv/static/status/jquery-visibility.min.js /opt/jquery-visibility/jquery-visibility.js',
    path        => '/bin:/usr/bin',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/jquery-visibility'],
    require     => [
      File['/srv/static/status'],
      Package['yui-compressor'],
      Vcsrepo['/opt/jquery-visibility'],
    ],
  }

  vcsrepo { '/opt/jquery-graphite':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://github.com/prestontimmons/graphitejs.git',
  }

  file { '/srv/static/status/jquery-graphite.js':
    ensure  => link,
    target  => '/opt/jquery-graphite/jquery.graphite.js',
    require => [File['/srv/static/status'],
                Vcsrepo['/opt/jquery-graphite']],
  }
  vcsrepo { '/opt/flot':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://github.com/flot/flot.git',
  }

  exec { 'install_flot' :
    command     => 'yui-compressor -o \'.js$:.min.js\' /opt/flot/jquery.flot*.js; mv /opt/flot/jquery.flot*.min.js /srv/static/status',
    path        => '/bin:/usr/bin',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/flot'],
    require     => [
      File['/srv/static/status'],
      Package['yui-compressor'],
      Vcsrepo['/opt/flot'],
    ],
  }

  ###########################################################
  # Status - elastic-recheck
  include elastic_recheck

  class { 'elastic_recheck::bot':
    gerrit_host             => $gerrit_host,
    gerrit_ssh_host_key     => $gerrit_ssh_host_key,
    recheck_ssh_public_key  => $recheck_ssh_public_key,
    recheck_ssh_private_key => $recheck_ssh_private_key,
    recheck_bot_passwd      => $recheck_bot_passwd,
    recheck_bot_nick        => $recheck_bot_nick,
  }

  # sets up the cron update scripts for static pages
  include elastic_recheck::cron

  ###########################################################
  # Status - reviewday

  include reviewday

  reviewday::site { 'reviewday':
    git_url                       => 'https://git.openstack.org/openstack-infra/reviewday',
    serveradmin                   => 'webmaster@openstack.org',
    httproot                      => '/srv/static/reviewday',
    gerrit_url                    => 'review.openstack.org',
    gerrit_port                   => '29418',
    gerrit_user                   => 'reviewday',
    reviewday_gerrit_ssh_key      => $gerrit_ssh_host_key,
    reviewday_rsa_pubkey_contents => $reviewday_ssh_public_key,
    reviewday_rsa_key_contents    => $reviewday_ssh_private_key,
  }

  ###########################################################
  # Status - bugdaystats

  include bugdaystats

  bugdaystats::site { 'bugdaystats':
    git_url     => 'https://git.openstack.org/openstack-infra/bugdaystats',
    serveradmin => 'webmaster@openstack.org',
    httproot    => '/srv/static/bugdaystats',
    configfile  => '/var/lib/bugdaystats/config.js',
  }
  ###########################################################
  # Status - openstack-health

  include 'openstack_health'

  openstack_health::site { 'openstack-health':
    httproot     => '/srv/static/openstack-health',
    api_endpoint => $openstack_health_api_endpoint
  }
}
