# Copyright 2012-2013 Hewlett-Packard Development Company, L.P.
# Copyright 2013 OpenStack Foundation
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

# == Class: subunit2sql
#
class subunit2sql::server (
  $db_dialect = 'mysql',
  $db_user = 'subunit2sql',
  $db_pass,
  $db_host,
  $db_port = '3306',
  $db_name = 'subunit2sql',
) {

  file { '/etc/subunit2sql.conf':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    content => template('subunit2sql/subunit2sql.conf.erb'),
  }

  exec { 'upgrade_subunit2sql_db':
    command     => 'subunit2sql-db-manage --config-file /etc/subunit2sql.conf upgrade head',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    subscribe   => Package['subunit2sql'],
    refreshonly => true,
  }
}
