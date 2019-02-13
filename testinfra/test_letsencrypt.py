# Copyright 2019 Red Hat, Inc.
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

import pytest

testinfra_hosts = ['adns1.opendev.org',
                   'test01.opendev.org',
                   'test02.opendev.org']

@pytest.mark.testinfra_hosts("adns1.opendev.org")
def test_acme_zone(host):
    acme_opendev_zone = host.file('/var/lib/bind/zones/acme.opendev.org')
    assert opendev_zone.exists
    # TODO : test TXT entries are in here

@pytest.mark.testinfra_hosts("test01.opendev.org")
def test_certs_created(host):
    domain_one = host.file('/etc/letsencrypt-certs/test01.opendev.org/test01.opendev.org.key')
    assert domain_one.exists
    domain_two = host.file('/etc/letsencrypt-certs/foo.opendev.org/foo.opendev.org.key')
    assert domain_two.exists
