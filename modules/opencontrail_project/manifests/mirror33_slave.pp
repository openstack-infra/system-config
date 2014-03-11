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
# Install a python33 mirror building slave.

class openstack_project::mirror33_slave (
  $jenkins_ssh_public_key,
  $jenkins_ssh_private_key,
) {

  class { 'openstack_project::mirror_slave':
    jenkins_ssh_public_key  => $jenkins_ssh_public_key,
    jenkins_ssh_private_key => $jenkins_ssh_private_key,
    python3                 => true,
  }
}
