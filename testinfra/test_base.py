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

import socket


def get_ips(value, family=None):
    ret = set()
    try:
        addr_info = socket.getaddrinfo(value, None, family)
    except socket.gaierror:
        return ret
    for addr in addr_info:
        ret.add(addr[4][0])
    return ret


def test_exim_is_installed(host):
    if host.system_info.distribution in ['ubuntu', 'debian']:
        exim = host.package("exim4-base")
    else:
        exim = host.package("exim")
    assert exim.is_installed

    cmd = host.run("exim -bt root")
    assert cmd.rc == 0

def test_ansible_group_on_bridge(host):
    '''Check for "ansible" group

    There should be an "ansible" group on bridge.o.o, but not on other
    hosts where ansible is not installed.  Ansible running directories
    should be in this group.
    '''
    ansible_vars = host.ansible.get_variables()
    if ansible_vars['inventory_hostname'] == 'bridge.openstack.org':
        assert host.group("ansible").exists
        ansible_cache = host.file('/var/cache/ansible')
        assert ansible_cache.user == 'root'
        assert ansible_cache.group == 'ansible'
        assert ansible_cache.mode == 0o4770

        ansible_log = host.file('/var/log/ansible')
        assert ansible_log.user == 'root'
        assert ansible_log.group == 'ansible'
        assert ansible_log.mode == 0o4775
    else:
        assert not host.group("ansible").exists


def test_iptables(host):
    rules = host.iptables.rules()
    rules = [x.strip() for x in rules]

    start = [
        '-P INPUT ACCEPT',
        '-P FORWARD ACCEPT',
        '-P OUTPUT ACCEPT',
        '-N openstack-INPUT',
        '-A INPUT -j openstack-INPUT',
        '-A openstack-INPUT -i lo -j ACCEPT',
        '-A openstack-INPUT -p icmp -m icmp --icmp-type any -j ACCEPT',
        '-A openstack-INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT',
        '-A openstack-INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT',
    ]
    assert rules[:len(start)] == start

    reject = '-A openstack-INPUT -j REJECT --reject-with icmp-host-prohibited'
    assert reject in rules

    # Make sure that the zuul console stream rule has been removed
    # from the test node
    zuul = ('-A openstack-INPUT -p tcp -m state --state NEW'
            ' -m tcp --dport 19885 -j ACCEPT')
    assert zuul not in rules

    # Ensure all IPv4 addresses for cacti are allowed
    for ip in get_ips('cacti.openstack.org', socket.AF_INET):
        snmp = ('-A openstack-INPUT -s %s/32 -p udp -m udp'
                ' --dport 161 -j ACCEPT' % ip)
        assert snmp in rules


def test_ntp(host):
    package = host.package("ntp")
    assert package.is_installed

    if host.system_info.distribution in ['ubuntu', 'debian']:
        service = host.service("ntp")
    else:
        service = host.service("ntpd")
    assert service.is_running
    assert service.is_enabled


def test_snmp(host):
    service = host.service("snmpd")
    assert service.is_running
    assert service.is_enabled


def test_timezone(host):
    tz = host.check_output('date +%Z')
    assert tz == "UTC"
