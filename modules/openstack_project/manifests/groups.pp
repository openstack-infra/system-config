# Copyright 2013  OpenStack Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# User group management server
#
class openstack_project::groups (
  $site_admin_password = '',
  $site_mysql_host     = '',
  $site_mysql_password = '',
  $site_mysql_user = 'groups',
  $conf_cron_key = '',
  $sysadmins = [],
  $site_ssl_cert_file_contents = undef,
  $site_ssl_key_file_contents = undef,
  $site_ssl_chain_file_contents = undef,
  $site_ssl_cert_file = '/etc/ssl/certs/groups.openstack.org.pem',
  $site_ssl_key_file = '/etc/ssl/private/groups.openstack.org.key',
  $site_ssl_chain_file = '/etc/ssl/certs/groups.openstack.org_ca.pem',
) {

  realize (
    User::Virtual::Localuser['mkiss'],
  )

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443],
    sysadmins                 => $sysadmins,
  }

  vcsrepo { '/srv/groups-static-pages':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://git.openstack.org/openstack-infra/groups-static-pages',
  }

  class { 'drupal':
    site_name                    => 'groups.openstack.org',
    site_root                    => '/srv/vhosts/groups.openstack.org',
    site_mysql_host              => $site_mysql_host,
    site_mysql_user              => $site_mysql_user,
    site_mysql_password          => $site_mysql_password,
    site_mysql_database          => 'groups',
    site_vhost_root              => '/srv/vhosts',
    site_admin_password          => $site_admin_password,
    site_alias                   => 'groups',
    site_profile                 => 'groups',
    site_base_url                => 'http://groups.openstack.org',
    site_ssl_enabled             => true,
    site_ssl_cert_file_contents  => $site_ssl_cert_file_contents,
    site_ssl_key_file_contents   => $site_ssl_key_file_contents,
    site_ssl_chain_file_contents => $site_ssl_chain_file_contents,
    site_ssl_cert_file           => $site_ssl_cert_file,
    site_ssl_key_file            => $site_ssl_key_file,
    site_ssl_chain_file          => $site_ssl_chain_file,
    package_repository           => 'http://tarballs.openstack.org/groups/drupal-updates/release-history',
    package_branch               => 'stable',
    conf                         => {
      'cron_key'                        => $conf_cron_key,
      'groups_feeds_markdown_directory' => '/srv/groups-static-pages',
      'googleanalytics_account'         => 'UA-17511903-1',
      'groups_openid_provider'          => 'https://openstackid.org'
    },
    require                      => [ Class['openstack_project::server'],
      Vcsrepo['/srv/groups-static-pages'] ],
  }

  mysql_backup::backup_remote { 'groups':
    database_host     => $site_mysql_host,
    database_user     => $site_mysql_user,
    database_password => $site_mysql_password,
    require           => Class['drupal'],
  }

  include bup
  bup::site { 'rs-ord':
    backup_user   => 'bup-groups',
    backup_server => 'ci-backup-rs-ord.openstack.org',
  }

}
