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
  $sysadmins = [],
) {

  realize (
    User::Virtual::Localuser['mkiss'],
  )

#  include drupal

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443],
    sysadmins                 => $sysadmins,
  }

  class { 'drupal':
    site_name            => 'groups-dev.openstack.org',
    site_docroot         => '/srv/vhosts/groups-dev.openstack.org',
    site_mysql_host      => $site_mysql_host,
    site_mysql_user      => 'groups',
    site_mysql_password  => $site_mysql_password,
    site_mysql_database  => 'groups_dev',
    site_vhost_root      => '/srv/vhosts',
    site_staging_tarball => 'groups-dev.tar.gz',
    site_admin_password  => $site_admin_password,
    site_build_reponame  => 'groups-master',
    site_makefile        => 'build-groups.make',
    site_repo_url        => 'https://git.openstack.org/openstack-infra/groups',
    site_profile         => 'groups',
    site_base_url        => 'http://groups-dev.openstack.org',
    require              => Class['openstack_project::server'],
  }

}
