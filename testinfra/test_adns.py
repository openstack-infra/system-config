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


testinfra_hosts = ['adns1.opendev.org']


def test_bind(host):
    named = host.service('bind9')
    assert named.is_running

def test_zone_files(host):
    opendev_zone = host.file('/var/lib/bind/zones/opendev.org')
    assert opendev_zone.exists

    acme_opendev_zone = host.file('/var/lib/bind/zones/acme.opendev.org')
    assert acme_opendev_zone.exists

    zuul_ci_zone = host.file('/var/lib/bind/zones/zuul-ci.org')
    assert zuul_ci_zone.exists

    zuulci_zone = host.file('/var/lib/bind/zones/zuulci.org')
    assert zuulci_zone.exists

    bind_config = host.file('/etc/bind/named.conf')
    assert b'zone opendev.org {' in bind_config.content
    assert b'zone acme.opendev.org {' in bind_config.content
    assert b'zone zuul-ci.org {' in bind_config.content
    assert b'zone zuulci.org {' in bind_config.content
