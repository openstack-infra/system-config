# Copyright 2017 IBM Corp.
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
# subunit2sql db server glue class.
#
class openstack_project::subunit_db_server (
  $subunit2sql_db_pass,
  $root_mysql_pass,
  $expire_age = '186',
  $expire_cron_minute = '0',
  $expire_cron_hour = '3',
  $expire_cron_weekday = '7',
  $subunit2sql_db_host = 'localhost',
  $subunit2sql_db_user = 'subunit2sql',
  $subunit2sql_db_name = 'subunit2sql',
) {

  class { '::mysql::server':
    service_name     => 'mysql',
    root_password    => $root_mysql_pass,
    override_options => {
      mysqld => {
        'max_connections' => '1024',
      }
    }
  }

  include mysql::server::account_security

  mysql::db { $subunit2sql_db_name:
    charset  => 'utf8',
    user     => $subunit2sql_db_user,
    password => $subunit2sql_db_pass,
    grant    => ['ALL'],
    require  => [
      Class['mysql::server'],
      Class['mysql::server::account_security'],
    ],
  }

  mysql_user { 'query'@'%':
    ensure        => 'present',
    password_hash => '*9C1A98FDC07907D9E7956EBBC4741B1E9C2B5DBB',
    require       => Db[$subunit2sql_db_name],
  }

  file { '/usr/local/bin/subunit_db_user.sh':
    ensure => present,
    source => 'puppet:///modules/openstack_project/subunit_db_user.sh',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

#  exec { 'create_db_user':
#    command => "/usr/local/bin/subunit_db_user.sh $subunit2sql_db_user $subunit2sql_db_pass $subunit2sql_db_name",
#    require => [
#        Mysql::Db[$subunit2sql_db_name],
#        File['/usr/local/bin/subunit_db_user.sh'],
#    ],
#  }

  include subunit2sql
  class { 'subunit2sql::server':
    db_host             => $subunit2sql_db_host,
    db_pass             => $subunit2sql_db_pass,
    expire_age          => $expire_age,
    expire_cron_minute  => $expire_cron_minute,
    expire_cron_hour    => $expire_cron_hour,
    expire_cron_weekday => $expire_cron_weekday,
    require             => Mysql::Db[$subunit2sql_db_name],
  }
}
