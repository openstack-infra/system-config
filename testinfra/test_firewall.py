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

# TODO(ianw): docker fiddles the firewall rules; update these to
# handle docker too.
testinfra_hosts = ['all:!bionic-docker']


def get_ips(value, family=None):
    ret = set()
    try:
        addr_info = socket.getaddrinfo(value, None, family)
    except socket.gaierror:
        return ret
    for addr in addr_info:
        ret.add(addr[4][0])
    return ret


def test_iptables(host):
    rules = host.iptables.rules()
    rules = [x.strip() for x in rules]

    start = [
        '-P INPUT ACCEPT',
        '-P FORWARD DROP',
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

    # Make sure that the zuul console stream rule is still present
    zuul = ('-A openstack-INPUT -p tcp -m state --state NEW'
            ' -m tcp --dport 19885 -j ACCEPT')
    assert zuul in rules

    # Ensure all IPv4+6 addresses for cacti are allowed
    for ip in get_ips('cacti.openstack.org', socket.AF_INET):
        snmp = ('-A openstack-INPUT -s %s/32 -p udp -m udp'
                ' --dport 161 -j ACCEPT' % ip)
        assert snmp in rules

    # TODO(ianw) add ip6tables support to testinfra iptables module
    ip6rules = host.check_output('ip6tables -S')
    for ip in get_ips('cacti.openstack.org', socket.AF_INET6):
        snmp = ('-A openstack-INPUT -s %s/128 -p udp -m udp'
                ' --dport 161 -j ACCEPT' % ip)
        assert snmp in ip6rules
