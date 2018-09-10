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


testinfra_hosts = ['mirror01.openstack.org']


def test_mirror_mounted(host):
    mirror_dir = host.file('/afs/openstack.org/mirror/centos')
    assert mirror_dir.exists
    assert mirror_dir.is_directory


def test_website_listening(host):
    assert host.socket("tcp://0.0.0.0:80").is_listening


def test_reverse_proxy_listening(host):
    assert host.socket("tcp://0.0.0.0:8080").is_listening
    assert host.socket("tcp://0.0.0.0:8081").is_listening
    assert host.socket("tcp://0.0.0.0:8082").is_listening
