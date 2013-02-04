# == Class: openstack_project::static
#
class openstack_project::static (
  $sysadmins = []
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

  a2mod { 'rewrite':
    ensure => present,
  }
  a2mod { 'proxy':
    ensure => present,
  }
  a2mod { 'proxy_http':
    ensure => present,
  }

  apache::vhost { 'tarballs.openstack.org':
    port     => 80,
    priority => '50',
    docroot  => '/srv/static/tarballs',
    require  => File['/srv/static/tarballs'],
  }

  apache::vhost { 'ci.openstack.org':
    port     => 80,
    priority => '50',
    docroot  => '/srv/static/ci',
    require  => File['/srv/static/ci'],
  }

  apache::vhost { 'logs.openstack.org':
    port     => 80,
    priority => '50',
    docroot  => '/srv/static/logs',
    require  => File['/srv/static/logs'],
    template => 'openstack_project/logs.vhost.erb',
  }

  apache::vhost { 'docs-draft.openstack.org':
    port     => 80,
    priority => '50',
    docroot  => '/srv/static/docs-draft',
    require  => File['/srv/static/docs-draft'],
  }

  apache::vhost { 'status.openstack.org':
    port     => 80,
    priority => '50',
    docroot  => '/srv/static/status',
    template => 'openstack_project/status.vhost.erb',
    require  => File['/srv/static/status'],
  }

  file { '/srv/static':
    ensure => directory,
  }

  file { '/srv/static/tarballs':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    require => User['jenkins'],
  }

  file { '/srv/static/ci':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    require => User['jenkins'],
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

  file { '/srv/static/docs-draft':
    ensure => directory,
  }

  file { '/srv/static/docs-draft/robots.txt':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    source  => 'puppet:///modules/openstack_project/disallow_robots.txt',
    require => File['/srv/static/docs-draft'],
  }

  file { '/srv/static/status':
    ensure => directory,
  }

  file { '/srv/static/status/index.html':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/status/index.html',
    require => File['/srv/static/status'],
  }

  cron { 'gziplogs':
    user        => 'root',
    minute      => '0',
    hour        => '*/6',
    command     => 'sleep $((RANDOM\%600)) && flock -n /var/run/gziplogs.lock find /srv/static/logs/ -type f -not -name robots.txt -not -name \*.gz \( -name \*.txt -or -name \*.html -or -name tmp\* \) -exec gzip \{\} \;',
    environment => 'PATH=/var/lib/gems/1.8/bin:/usr/bin:/bin:/usr/sbin:/sbin',
  }

  include ::reviewday

  reviewday::site { 'reviewday.openstack.org':
    git_url     => 'https://github.com/openstack-infra/reviewday.git',
    serveradmin => 'webmaster@openstack.org',
    httproot    => "/srv/static/${name}",
  }
  reviewday::init { 'reviewday.openstack.org':
    gerrit_url  => 'review.openstack.org',
    gerrit_port => '29418',
    gerrit_user => 'reviewday',
  }
}
