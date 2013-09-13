# == Class: openstack_project::static
#
class openstack_project::static (
  $sysadmins = [],
  $reviewday_gerrit_ssh_key = '',
  $reviewday_rsa_pubkey_contents = '',
  $reviewday_rsa_key_contents = '',
  $releasestatus_prvkey_contents = '',
  $releasestatus_pubkey_contents = '',
  $releasestatus_gerrit_ssh_key = '',
) {

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443],
    sysadmins                 => $sysadmins,
  }

  include openstack_project
  class { 'jenkins::jenkinsuser':
    ssh_key => $openstack_project::jenkins_ssh_key,
  }

  include apache
  include apache::mod::wsgi

  a2mod { 'rewrite':
    ensure => present,
  }
  a2mod { 'proxy':
    ensure => present,
  }
  a2mod { 'proxy_http':
    ensure => present,
  }

  file { '/srv/static':
    ensure => directory,
  }

  ###########################################################
  # Tarballs

  apache::vhost { 'tarballs.openstack.org':
    port     => 80,
    priority => '50',
    docroot  => '/srv/static/tarballs',
    require  => File['/srv/static/tarballs'],
  }

  file { '/srv/static/tarballs':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    require => User['jenkins'],
  }

  ###########################################################
  # CI

  apache::vhost { 'ci.openstack.org':
    port     => 80,
    priority => '50',
    docroot  => '/srv/static/ci',
    require  => File['/srv/static/ci'],
  }

  file { '/srv/static/ci':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    require => User['jenkins'],
  }

  ###########################################################
  # Logs

  apache::vhost { 'logs.openstack.org':
    port     => 80,
    priority => '50',
    docroot  => '/srv/static/logs',
    require  => File['/srv/static/logs'],
    template => 'openstack_project/logs.vhost.erb',
  }

  apache::vhost { 'logs-dev.openstack.org':
    port     => 80,
    priority => '51',
    docroot  => '/srv/static/logs',
    require  => File['/srv/static/logs'],
    template => 'openstack_project/logs-dev.vhost.erb',
  }

  file { '/srv/static/logs':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    require => User['jenkins'],
  }

  file { '/srv/static/logs/robots.txt':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    source  => 'puppet:///modules/openstack_project/disallow_robots.txt',
    require => File['/srv/static/logs'],
  }

  file { '/usr/local/bin/htmlify-screen-log.py':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/openstack_project/logs/htmlify-screen-log.py',
  }

  file { '/srv/static/logs/help':
    ensure  => directory,
    recurse => true,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/openstack_project/logs/help',
    require => File['/srv/static/logs'],
  }

  file { '/usr/local/sbin/log_archive_maintenance.sh':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0744',
    source => 'puppet:///modules/openstack_project/log_archive_maintenance.sh',
  }

  cron { 'gziprmlogs':
    user        => 'root',
    minute      => '0',
    hour        => '7',
    weekday     => '6',
    command     => 'bash /usr/local/sbin/log_archive_maintenance.sh',
    environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
    require     => File['/usr/local/sbin/log_archive_maintenance.sh'],
  }

  ###########################################################
  # Docs-draft

  apache::vhost { 'docs-draft.openstack.org':
    port     => 80,
    priority => '50',
    docroot  => '/srv/static/docs-draft',
    require  => File['/srv/static/docs-draft'],
  }

  file { '/srv/static/docs-draft':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    require => User['jenkins'],
  }

  file { '/srv/static/docs-draft/robots.txt':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    source  => 'puppet:///modules/openstack_project/disallow_robots.txt',
    require => File['/srv/static/docs-draft'],
  }

  ###########################################################
  # Pypi Mirror

  apache::vhost { 'pypi.openstack.org':
    port     => 80,
    priority => '50',
    docroot  => '/srv/static/pypi',
    require  => File['/srv/static/pypi'],
  }

  file { '/srv/static/pypi':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    require => User['jenkins'],
  }

  file { '/srv/static/pypi/robots.txt':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    source  => 'puppet:///modules/openstack_project/disallow_robots.txt',
    require => File['/srv/static/pypi'],
  }

  ###########################################################
  # Status

  apache::vhost { 'status.openstack.org':
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
    source  => 'puppet:///modules/openstack_project/status/common.js',
    require => File['/srv/static/status'],
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
    require     => [File['/srv/static/status'],
                    Vcsrepo['/opt/jquery-visibility']],
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

  ###########################################################
  # Status - zuul

  file { '/srv/static/status/zuul':
    ensure => directory,
  }

  file { '/srv/static/status/zuul/index.html':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/zuul/status.html',
    require => File['/srv/static/status/zuul'],
  }

  file { '/srv/static/status/zuul/status.js':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/zuul/status.js',
    require => File['/srv/static/status/zuul'],
  }

  ###########################################################
  # Status - reviewday

  include reviewday

  reviewday::site { 'reviewday':
    git_url                       => 'git://git.openstack.org/openstack-infra/reviewday',
    serveradmin                   => 'webmaster@openstack.org',
    httproot                      => '/srv/static/reviewday',
    gerrit_url                    => 'review.openstack.org',
    gerrit_port                   => '29418',
    gerrit_user                   => 'reviewday',
    reviewday_gerrit_ssh_key      => $reviewday_gerrit_ssh_key,
    reviewday_rsa_pubkey_contents => $reviewday_rsa_pubkey_contents,
    reviewday_rsa_key_contents    => $reviewday_rsa_key_contents,
  }

  ###########################################################
  # Status - releasestatus

  class { 'releasestatus':
    releasestatus_prvkey_contents => $releasestatus_prvkey_contents,
    releasestatus_pubkey_contents => $releasestatus_pubkey_contents,
    releasestatus_gerrit_ssh_key  => $releasestatus_gerrit_ssh_key,
  }

  releasestatus::site { 'releasestatus':
    configfile => 'integrated.yaml',
    httproot   => '/srv/static/release',
  }
}
