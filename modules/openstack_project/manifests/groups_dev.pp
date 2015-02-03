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
# User group management dev server
#
class openstack_project::groups_dev (
  $site_admin_password = '',
  $site_mysql_host     = '',
  $site_mysql_password = '',
  $conf_cron_key = '',
  $sysadmins = [],
  $site_ssl_cert_file_contents = undef,
  $site_ssl_key_file_contents = undef,
  $site_ssl_cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem',
  $site_ssl_key_file = '/etc/ssl/private/ssl-cert-snakeoil.key',
) {

  realize (
    User::Virtual::Localuser['mkiss'],
  )

#  include drupal

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
    site_name                    => 'groups-dev.openstack.org',
    site_root                    => '/srv/vhosts/groups-dev.openstack.org',
    site_mysql_host              => $site_mysql_host,
    site_mysql_user              => 'groups',
    site_mysql_password          => $site_mysql_password,
    site_mysql_database          => 'groups_dev',
    site_vhost_root              => '/srv/vhosts',
    site_admin_password          => $site_admin_password,
    site_alias                   => 'groupsdev',
    site_profile                 => 'groups',
    site_base_url                => 'http://groups-dev.openstack.org',
    site_ssl_enabled             => true,
    site_ssl_cert_file_contents  => $site_ssl_cert_file_contents,
    site_ssl_key_file_contents   => $site_ssl_key_file_contents,
    site_ssl_cert_file           => $site_ssl_cert_file,
    site_ssl_key_file            => $site_ssl_key_file,
    package_repository           => 'http://tarballs.openstack.org/groups/drupal-updates/release-history',
    package_branch               => 'dev',
    conf                         => {
      'cron_key'                        => $conf_cron_key,
      'groups_feeds_markdown_directory' => '/srv/groups-static-pages',
      'groups_openid_provider'          => 'https://openstackid.org'
    },
    require                      => [ Class['openstack_project::server'],
      Vcsrepo['/srv/groups-static-pages'] ]
  }

}
