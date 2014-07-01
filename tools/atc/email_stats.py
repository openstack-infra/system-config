#!/usr/bin/env python

# Copyright (C) 2013-2014 OpenStack Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
#
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Soren Hansen wrote the original version of this script.
# James Blair hacked it up to include email addresses from gerrit.
# Jeremy Stanley overhauled it for gerrit 2.8 and our governance repo.

import csv
import datetime
import json
import optparse
import os
import os.path
import re

import paramiko
import requests
import yaml

MAILTO_RE = re.compile('mailto:(.*)')
USERNAME_RE = re.compile('username:(.*)')
EXTRA_ATC_RE = re.compile('[^:]*: ([^\(]*) \(([^@]*@[^\)]*)\) \[[^\[]*\]')
PROGRAMS_URL = ('https://git.openstack.org/cgit/openstack/governance/plain'
                '/reference/programs.yaml')
EXTRA_ATCS_URL = ('https://git.openstack.org/cgit/openstack/governance/plain'
                  '/reference/extra-atcs')


class Account(object):
    def __init__(self, num):
        self.num = num
        self.full_name = ''
        self.emails = []
        self.username = None


def get_account(accounts, num):
    a = accounts.get(num)
    if not a:
        a = Account(num)
        accounts[num] = a
    return a


def project_stats(project, output, begin, end, keyfile, user):
    accounts = {}

    for row in open('accounts.tab'):
        if not row.startswith('registered_on'):
            row = row.split('\t')
            num = int(row[13])
            name = row[1]
            email = row[2]
            a = get_account(accounts, num)
            a.full_name = name
            if email and email != 'NULL':
                a.emails.append(email)

    for row in open('emails.tab'):
        if not row.startswith('account_id'):
            num, email, pw, external = row.split('\t')
            num = int(num)
            a = get_account(accounts, num)
            if email and email != 'NULL' and email not in a.emails:
                a.emails.append(email)
            m = MAILTO_RE.match(external)
            if m:
                if m.group(1) not in a.emails:
                    a.emails.append(m.group(1))
            m = USERNAME_RE.match(external)
            if m:
                if a.username:
                    print a.num
                    print a.username
                    raise Exception("Already a username")
                a.username = m.group(1)

    username_accounts = {}
    for a in accounts.values():
        username_accounts[a.username] = a

    atcs = []

    QUERY = "project:%s status:merged" % project

    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.load_system_host_keys()
    client.connect(
        'review.openstack.org', port=29418,
        key_filename=os.path.expanduser(keyfile), username=user)
    stdin, stdout, stderr = client.exec_command(
        'gerrit query %s --all-approvals --format JSON' % QUERY)

    done = False
    last_sortkey = ''
    start_date = datetime.datetime(int(begin[0:4]), int(begin[4:6]),
                                   int(begin[6:8]), 0, 0, 0)
    end_date = datetime.datetime(int(end[0:4]), int(end[4:6]), int(end[6:8]),
                                 0, 0, 0)

    count = 0
    earliest = datetime.datetime.now()
    while not done:
        for l in stdout:
            data = json.loads(l)
            if 'rowCount' in data:
                if data['rowCount'] < 500:
                    done = True
                continue
            count += 1
            last_sortkey = data['sortKey']
            if 'owner' not in data:
                continue
            if 'username' not in data['owner']:
                continue
            account = username_accounts[data['owner']['username']]
            approved = False
            for ps in data['patchSets']:
                if 'approvals' not in ps:
                    continue
                for aprv in ps['approvals']:
                    if aprv['type'] != 'SUBM':
                        continue
                    ts = datetime.datetime.fromtimestamp(aprv['grantedOn'])
                    if ts < start_date or ts > end_date:
                        continue
                    approved = True
                    if ts < earliest:
                        earliest = ts
            if approved and account not in atcs:
                atcs.append(account)
        if not done:
            stdin, stdout, stderr = client.exec_command(
                'gerrit query %s resume_sortkey:%s --all-approvals'
                ' --format JSON' % (QUERY, last_sortkey))

    print 'project: %s' % project
    print 'examined %s changes' % count
    print 'earliest timestamp: %s' % earliest
    writer = csv.writer(open(output, 'w'))
    for a in atcs:
        writer.writerow([a.username, a.full_name] + a.emails)
    print


def get_projects(url):
    programs_yaml = yaml.load(requests.get(url).text)
    projects = []
    for program in programs_yaml:
        for project in programs_yaml[program]['projects']:
            projects.append(project['repo'])
    return projects


def get_extra_atcs(url):
    extra_atcs = []
    for line in requests.get(url).text.split('\n'):
        if line and not line.startswith('#'):
            extra_atcs.append(line)
    return extra_atcs


def main():
    today = ''.join(
            '%02d' % x for x in datetime.datetime.utcnow().utctimetuple()[:3])

    optparser = optparse.OptionParser()
    optparser.add_option(
        '-b', '--begin', help='begin date (e.g. 20131017)')
    optparser.add_option(
        '-e', '--end', default=today, help='end date (default is today)')
    optparser.add_option(
        '-k', '--keyfile', default='~/.ssh/id_rsa',
        help='SSH key (default is ~/.ssh/id_rsa)')
    optparser.add_option(
        '-u', '--user', default=os.environ['USER'],
        help='SSH username (default is $USER)')
    options, args = optparser.parse_args()

    for project in get_projects(PROGRAMS_URL):
        output = 'out/%s.csv' % project.split('/')[-1]
        project_stats(project, output, options.begin, options.end,
                      options.keyfile, options.user)

    writer = csv.writer(open('out/extra-atcs.csv', 'w'))
    for atc in get_extra_atcs(EXTRA_ATCS_URL):
        writer.writerow([''] + list(EXTRA_ATC_RE.match(atc).groups()))


if __name__ == "__main__":
    main()
