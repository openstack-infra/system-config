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
class openstack_project::openid_dev (
  $mysql_root_password = '',
  $sysadmins = [],
  $db_name  = 'openstackid_openid',
  $redis_port = '6378',
  $redis_max_memory = '1gb',
  $redis_bind = '127.0.0.1',
) {
  realize (
    User::Virtual::Localuser['smarcet'],
  )

  class { 'mysql::server':
    root_password => $mysql_root_password,
  }

  mysql_database {
    $db_name:
    ensure  => present,
    charset => 'utf8',
    require => Class['mysql::server'],
  }

  # php packages needed for openid server
  # we need PHP 5.4 or greather
  
  package { ['php5-common','php5-curl','php5-cli','php5-json','php5-mcrypt','php5-mysql']:
    ensure => installed,
    ensure => '5.4',
  }

  # redis (custom module written by tipit)

  class { 'redis':
    redis_port       => $redis_port,
    redis_max_memory => $redis_max_memory,
    redis_bind       => $redis_bind,
  }

  include apache
  include apache::ssl
  include apache::php

}
