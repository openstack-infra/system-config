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


testinfra_hosts = ['all']


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


def test_puppet(host):
    # We only install puppet on trusty, xenial and centos 7
    if (host.system_info.codename in ['trusty', 'xenial'] or
            host.system_info.distribution in ['centos']):
        # Package name differs depending on puppet release version
        # just check one version of puppet is installed.
        puppet = host.package("puppet")
        puppet_agent = host.package("puppet-agent")
        assert puppet.is_installed or puppet_agent.is_installed
        service = host.service("puppet")
        assert not service.is_running
        assert not service.is_enabled
    else:
        puppet = host.package("puppet")
        puppet_agent = host.package("puppet-agent")
        assert not puppet.is_installed and not puppet_agent.is_installed


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

    # Make sure that the zuul console stream rule is still present
    zuul = ('-A openstack-INPUT -p tcp -m state --state NEW'
            ' -m tcp --dport 19885 -j ACCEPT')
    assert zuul in rules

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


def test_unbound(host):
    output = host.check_output('host git.openstack.org')
    assert 'has address' in output


def test_unattended_upgrades(host):
    if host.system_info.distribution in ['ubuntu', 'debian']:
        package = host.package("unattended-upgrades")
        assert package.is_installed

        package = host.package("mailutils")
        assert package.is_installed

        cfg_file = host.file("/etc/apt/apt.conf.d/10periodic")
        assert cfg_file.exists
        assert cfg_file.contains('^APT::Periodic::Enable "1"')
        assert cfg_file.contains('^APT::Periodic::Update-Package-Lists "1"')
        assert cfg_file.contains('^APT::Periodic::Download-Upgradeable-Packages "1"')
        assert cfg_file.contains('^APT::Periodic::AutocleanInterval "5"')
        assert cfg_file.contains('^APT::Periodic::Unattended-Upgrade "1"')
        assert cfg_file.contains('^APT::Periodic::RandomSleep "1800"')

        cfg_file = host.file("/etc/apt/apt.conf.d/50unattended-upgrades")
        assert cfg_file.contains('^Unattended-Upgrade::Mail "root"')

    else:
        package = host.package("yum-cron")
        assert package.is_installed

        service = host.service("crond")
        assert service.is_enabled
        assert service.is_running

        cfg_file = host.file("/etc/yum/yum-cron.conf")
        assert cfg_file.exists
        assert cfg_file.contains('apply_updates = yes')


def test_logrotate(host):
    '''Check for log rotation configuration files

       The magic number here is [0:5] of the sha1 hash of the full
       path to the rotated logfile; the role adds this for uniqueness.
    '''
    ansible_vars = host.ansible.get_variables()
    if ansible_vars['inventory_hostname'] == 'bridge.openstack.org':
        cfg_file = host.file("/etc/logrotate.d/ansible.log.37237.conf")
        assert cfg_file.exists
        assert cfg_file.contains('/var/log/ansible/ansible.log')
        cfg_file = host.file("/etc/logrotate.d/run_all_cron.log.1a953.conf")
        assert cfg_file.exists
        assert cfg_file.contains('/var/log/ansible/run_all_cron.log')

