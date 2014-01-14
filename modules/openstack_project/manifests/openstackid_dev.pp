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
# openstackid idp(sso-openid) dev server
#
class openstack_project::openstackid_dev (
  $sysadmins = [],
  $site_admin_password = '',
  $mysql_host = '',
  $mysql_user = 'openstackid',
  $mysql_password = '',
  $id_db_name = 'openstackid_openid_dev',
  $ss_db_name = 'openstackid_silverstripe_dev',
  $redis_port = '6378',
  $redis_max_memory = '1gb',
  $redis_bind = '127.0.0.1'
) {

  realize (
    User::Virtual::Localuser['smarcet'],
  )

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
    sysadmins                 => $sysadmins,
  }

  class { 'openstackid':
    site_admin_password => $site_admin_password,
    mysql_host          => $mysql_host,
    mysql_user          => $mysql_user,
    mysql_password      => $mysql_password,
    id_db_name          => $id_db_name,
    ss_db_name          => $ss_db_name,
    redis_port          => $redis_port,
    redis_host          => $redis_bind,
  }

  # redis (custom module written by tipit)
  class { 'redis':
    redis_port       => $redis_port,
    redis_max_memory => $redis_max_memory,
    redis_bind       => $redis_bind,
  }

}
