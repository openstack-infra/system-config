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
  $conf_cron_key = '',
  $sysadmins = [],
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
    site_name               => 'groups.openstack.org',
    site_root               => '/srv/vhosts/groups.openstack.org',
    site_mysql_host         => $site_mysql_host,
    site_mysql_user         => 'groups',
    site_mysql_password     => $site_mysql_password,
    site_mysql_database     => 'groups',
    site_vhost_root         => '/srv/vhosts',
    site_admin_password     => $site_admin_password,
    site_alias              => 'groups',
    site_profile            => 'groups',
    site_base_url           => 'http://groups.openstack.org',
    package_repository      => 'http://tarballs.openstack.org/groups',
    package_branch          => 'groups-latest',
    conf_cron_key           => $conf_cron_key,
    conf_markdown_directory => '/srv/groups-static-pages',
    require                 => [ Class['openstack_project::server'],
      Vcsrepo['/srv/groups-static-pages'] ]
  }

}
