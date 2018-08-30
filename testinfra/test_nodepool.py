# Copyright 2018 Red Hat, Inc.
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


testinfra_hosts = ['nl01.openstack.org', 'nb01.openstack.org']


def test_clouds_yaml(host):
    clouds_yaml = host.file('/home/nodepool/.config/openstack/clouds.yaml')
    assert clouds_yaml.exists

    assert 'password' in clouds_yaml.content
