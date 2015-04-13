# == Class: openstack_project::ask_dev
#
# ask-staging.openstack.org Q&A support website
#
class openstack_project::ask_dev (
  $sysadmins = [],
  $db_name = 'askbotdb',
  $db_user = undef,
  $db_password = undef,
  $slot_name = 'slot0',
  $redis_enabled = true,
  $redis_port = '6378',
  $redis_max_memory = '512m',
  $redis_bind = '127.0.0.1',
  $redis_password = undef,
  $site_ssl_enabled = true,
  $site_ssl_cert_file_contents = undef,
  $site_ssl_key_file_contents = undef,
  $site_ssl_chain_file_contents = undef,
  $site_ssl_cert_file = '/etc/ssl/certs/ask-staging.openstack.org.pem',
  $site_ssl_key_file = '/etc/ssl/private/ask-staging.openstack.org.key',
  $site_ssl_chain_file = '/etc/ssl/certs/ask-staging.openstack.org_ca.pem',
  $site_name = 'ask-staging.openstack.org',
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

}
