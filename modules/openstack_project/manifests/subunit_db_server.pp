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
class openstack_project::subunit_worker (
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

  class { '::mysql:server':
    package_name     => 'mariadb-server',
    service_name     => 'mysql',
    root_password    => $root_mysql_pass,
    override_options => {
      mysqld => {
        'max_connections' => '1024',
      }
    }
  }

  mysql::db { $subunit2sql_db_name:
    charset  => 'utf8',
    user     => $subunit2sql_db_user,
    password => $subunit2sql_db_pass,
    grant    => ['ALL'],
  }


  mysql::mysql_user { 'query':
    ensure   => 'present',
    password => 'query',
    require  => Db[$subunit2sql_db_name],
  }

  mysql::mysql_grant {
    ensure     => 'present',
    options    => ['GRANT'],
    privileges => ['SELECT'],
    table      => "${subunit2sql_db_name}.*",
    user       => 'query',
    require    => Mysql_user['query'],
  }

  include subunit2sql
  class { 'subunit2sql::server':
    db_host             => $subunit2sql_db_host,
    db_pass             => $subunit2sql_db_pass,
    expire_age          => $expire_age
    expire_cron_minute  => $expire_cron_minute,
    expire_cron_hour    => $expire_cron_hour,
    expire_cron_weekday => $expire_cron_weekday,
    require             => Db[$subunit2sql_db_name],
  }
}
