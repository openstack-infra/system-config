# == Class: openstack_project::ask
#
# ask.openstack.org Q&A support website
#
class openstack_project::ask (
  $sysadmins = [],
  $db_name = 'askbotdb',
  $db_user = undef,
  $db_password = undef,
  $slot_name = 'slot0',
  $redis_enabled = true,
  $redis_port = '6378',
  $redis_max_memory = '256m',
  $redis_bind = '127.0.0.1',
  $redis_password = undef,
  $site_ssl_enabled = true,
  $site_ssl_cert_file_contents = undef,
  $site_ssl_key_file_contents = undef,
  $site_ssl_chain_file_contents = undef,
  $site_ssl_cert_file = '/etc/ssl/certs/ask.openstack.org.pem',
  $site_ssl_key_file = '/etc/ssl/private/ask.openstack.org.key',
  $site_ssl_chain_file = '/etc/ssl/certs/ask.openstack.org_ca.pem',
  $site_name = 'ask.openstack.org',
  $solr_version = '4.7.2',
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443],
    sysadmins                 => $sysadmins,
  }

  # solr search engine
  class { 'solr':
    mirror  => 'http://apache.mesi.com.ar/lucene/solr',
    version => $solr_version,
    cores   => [ 'core-default', 'core-en', 'core-zh' ],
  }

  file { '/usr/share/solr/core-en/conf/schema.xml':
    ensure  => present,
    content => template('openstack_project/askbot/schema.en.xml.erb'),
    replace => true,
    owner   => 'jetty',
    group   => 'jetty',
    mode    => '0644',
    require => File['/usr/share/solr/core-zh/conf'],
  }

  file { '/usr/share/solr/core-zh/conf/schema.xml':
    ensure  => present,
    content => template('openstack_project/askbot/schema.cn.xml.erb'),
    replace => true,
    owner   => 'jetty',
    group   => 'jetty',
    mode    => '0644',
    require => File['/usr/share/solr/core-en/conf'],
  }

  # deploy smartcn Chinese analyzer from solr contrib/analysys-extras
  file { "/usr/share/solr/WEB-INF/lib/lucene-analyzers-smartcn-${solr_version}.jar":
    ensure  => present,
    replace => 'no',
    source  => "/tmp/solr-${solr_version}/contrib/analysis-extras/lucene-libs/lucene-analyzers-smartcn-${solr_version}.jar",
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Exec['copy-solr'],
  }

  # postgresql database
  class { 'postgresql::server': }

  postgresql::server::db { $db_name:
    user     => $db_user,
    password => postgresql_password($db_user, $db_password),
  }

  # redis cache
  class { 'redis':
    redis_port       => $redis_port,
    redis_max_memory => $redis_max_memory,
    redis_bind       => $redis_bind,
    redis_password   => $redis_password,
  }

  # apache http server
  include apache

  # askbot
  class { 'askbot':
    redis_enabled        => $redis_enabled,
    db_provider          => 'pgsql',
    require              => Postgresql::Server::Db[$db_name],
  }

  # custom askbot theme from openstack-infra/askbot-theme repo

  vcsrepo { "/srv/askbot-sites/${slot_name}/themes":
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://git.openstack.org/openstack-infra/askbot-theme',
    require  => [
      Class['askbot'], File["/srv/askbot-sites/${slot_name}"],
      Package['git']
    ],
    notify   => [
      Exec["theme-bundle-install-${slot_name}"],
      Exec["theme-bundle-compile-${slot_name}"],
    ],
  }

  askbot::compass { $slot_name:
  }

  askbot::site { $site_name:
    slot_name                    => $slot_name,
    askbot_debug                 => false,
    custom_theme_enabled         => true,
    custom_theme_name            => 'os',
    redis_enabled                => $redis_enabled,
    redis_port                   => $redis_port,
    redis_max_memory             => $redis_max_memory,
    redis_bind                   => $redis_bind,
    redis_password               => $redis_password,
    site_ssl_enabled             => true,
    site_ssl_cert_file_contents  => $site_ssl_cert_file_contents,
    site_ssl_key_file_contents   => $site_ssl_key_file_contents,
    site_ssl_chain_file_contents => $site_ssl_chain_file_contents,
    site_ssl_cert_file           => $site_ssl_cert_file,
    site_ssl_key_file            => $site_ssl_key_file,
    site_ssl_chain_file          => $site_ssl_chain_file,
    db_provider                  => 'pgsql',
    db_name                      => $db_name,
    db_user                      => $db_user,
    db_password                  => $db_password,
    require                      => [ Class['redis'], Class['askbot'] ],
  }
}