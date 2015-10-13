# Copyright 2013 Hewlett-Packard Development Company, L.P.
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
# subunit2sql worker glue class.
#
class openstack_project::subunit_worker (
  $sysadmins = [],
  $subunit2sql_db_host,
  $subunit2sql_db_pass,
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22],
    sysadmins                 => $sysadmins,
  }

  include subunit2sql
  subunit2sql::worker { 'A':
    config_file        => 'puppet:///modules/openstack_project/logstash/jenkins-subunit-worker.yaml',
    db_host            => $subunit2sql_db_host,
    db_pass            => $subunit2sql_db_pass,
  }
}
