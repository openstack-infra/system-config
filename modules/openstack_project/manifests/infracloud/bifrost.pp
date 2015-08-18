# Copyright 2014 Hewlett-Packard Development Company, L.P.
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
class openstack_project::infracloud::bifrost (
  $ironic_db_password,
  $mysql_password,
  $region,
) {

  include ::ansible

  class { '::mysql::server':
    root_password => $mysql_password,
  }

  class { '::ironic::bifrost':
    ironic_db_password   => $ironic_db_password,
    mysql_password       => $mysql_password,
    baremetal_json_hosts => {}, # use a static file instead
  }

  file { '/opt/stack/baremetal.json':
    ensure => file,
    content => template("bifrost/inventory.${region}.json.erb"),
  }

}
