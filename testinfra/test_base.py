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

def test_exim_is_installed(host):
    if host.system_info.distribution in ['ubuntu', 'debian']:
        exim = host.package("exim4-base")
    else:
        exim = host.package("exim")
    assert exim.is_installed

    cmd = host.run("exim -bt root")
    assert cmd.rc == 0

def test_ansible_group_on_bridge(host):
    ansible_vars = host.ansible.get_variables()
    if ansible_vars['inventory_hostname'] == 'bridge.openstack.org':
        assert host.group("ansible").exists
    else:
        assert False

