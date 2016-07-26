# Copyright 2016 Hewlett-Packard Development Company, L.P.
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
# firehose glue class.
#
class openstack_project::firehose (
  $gerrit_username = 'germqtt',
  $gerrit_public_key,
  $gerrit_private_key,
  $gerrit_ssh_host_key,
  $mqtt_hostname = 'firehose01.openstack.org',
) {
  include mosquitto
  class {'mosquitto::server':
    log_file => '/var/log/mosquitto.log',
  }

  include germqtt
  class {'germqtt::server':
    gerrit_username    => $gerrit_username,
    gerrit_public_key  => $gerrit_public_key,
    gerrit_private_key => $gerrit_private_key,
    gerrit_host_key    => $gerrit_host_key,
  }
}
