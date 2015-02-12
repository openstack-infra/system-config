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
EXTRA_ATC_RE = re.compile('^[^#][^:]*: ([^\(]*) \(([^@]*@[^\)]*)\) \[[^\[]*\]')
PROJECTS_URL = ('https://git.openstack.org/cgit/openstack/governance/plain'
                '/reference/projects.yaml')
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


def repo_stats(repo, output, begin, end, keyfile, user):
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

    QUERY = "project:%s status:merged" % repo

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
    begin_time = datetime.datetime(
        int(begin[0:4]), int(begin[4:6]), int(begin[6:8]),
        int(begin[8:10]), int(begin[10:12]), int(begin[12:14]))
    end_time = datetime.datetime(
        int(end[0:4]), int(end[4:6]), int(end[6:8]),
        int(end[8:10]), int(end[10:12]), int(end[12:14]))

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
                    if ts < begin_time or ts > end_time:
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

    print 'repo: %s' % repo
    print 'examined %s changes' % count
    print 'earliest timestamp: %s' % earliest
    writer = csv.writer(open(output, 'w'))
    for a in atcs:
        writer.writerow([a.username, a.full_name] + a.emails)
    print


def get_repos(url):
    projects_yaml = yaml.load(requests.get(url).text)
    repos = []
    for project in projects_yaml:
        for repo in projects_yaml[project]['projects']:
            repos.append(repo['repo'])
    return repos


def get_extra_atcs(url):
    extra_atcs = []
    for line in requests.get(url).text.split('\n'):
        if line and not line.startswith('#'):
            extra_atcs.append(line)
    return extra_atcs


def main():
    now = ''.join(
        '%02d' % x for x in datetime.datetime.utcnow().utctimetuple()[:6])

    optparser = optparse.OptionParser()
    optparser.add_option(
        '-b', '--begin', help='begin date/time (e.g. 20131017000000)')
    optparser.add_option(
        '-e', '--end', default=now, help='end date/time (default is now)')
    optparser.add_option(
        '-k', '--keyfile', default='~/.ssh/id_rsa',
        help='SSH key (default is ~/.ssh/id_rsa)')
    optparser.add_option(
        '-r', '--ref', default='',
        help='governance git ref (e.g. sept-2014-elections')
    optparser.add_option(
        '-u', '--user', default=os.environ['USER'],
        help='SSH username (default is $USER)')
    options, args = optparser.parse_args()

    if options.ref:
        projects_url = '%s?id=%s' % (PROJECTS_URL, options.ref)
        extra_atcs_url = '%s?id=%s' % (EXTRA_ATCS_URL, options.ref)
    else:
        projects_url = PROJECTS_URL
        extra_atcs_url = EXTRA_ATCS_URL

    for repo in get_repos(projects_url):
        output = 'out/%s.csv' % repo.split('/')[-1]
        repo_stats(repo, output, options.begin, options.end,
                   options.keyfile, options.user)

    writer = csv.writer(open('out/extra-atcs.csv', 'w'))
    for atc in get_extra_atcs(extra_atcs_url):
        try:
            writer.writerow([''] + list(EXTRA_ATC_RE.match(atc).groups()))
        except AttributeError:
            pass


if __name__ == "__main__":
    main()
