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
  $redis_max_memory = '256m'
  $redis_bind = '127.0.0.1'
  $redis_password = undef,
  $site_ssl_enabled = true,
  $site_ssl_cert_file_contents = undef,
  $site_ssl_key_file_contents = undef,
  $site_ssl_chain_file_contents = undef,
  $site_ssl_cert_file = '/etc/ssl/private/ssl-cert-snakeoil.key',
  $site_ssl_key_file = '/etc/ssl/private/groups-dev.openstack.org.key',
  $site_name = 'ask.openstack.org',
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443],
    sysadmins                 => $sysadmins,
  }

  # solr search engine
  class { 'solr':
    solr_dist => 'http://mirror.cc.columbia.edu/pub/software/apache/lucene/solr/4.10.2/solr-4.10.2.tgz',
  }

  solr::core { 'core-default':
  }

  solr::core { 'core-en':
    schema_conf_template => 'askbot/solr/schema.en.xml.erb',
  }

  solr::core { 'core-zh':
    schema_conf_template => 'askbot/solr/schema.cn.xml.erb',
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
  package { 'git':
    ensure => present,
  }

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
    site_ssl_cert_file           => $site_ssl_cert_file,
    site_ssl_key_file            => $site_ssl_key_file,
    site_ssl_chain_file_contents => $site_ssl_chain_file_contents,
    db_provider                  => 'pgsql',
    db_name                      => $db_name,
    db_user                      => $db_user,
    db_password                  => $db_password,
    require                      => [ Class['redis'], Class['askbot'] ],
  }
}