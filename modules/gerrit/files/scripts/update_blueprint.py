#!/usr/bin/env python
# Copyright (c) 2011 OpenStack, LLC.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

# This is designed to be called by a gerrit hook.  It searched new
# patchsets for strings like "blueprint FOO" or "bp FOO" and updates
# corresponding Launchpad blueprints with links back to the change.

from launchpadlib.launchpad import Launchpad
from launchpadlib.uris import LPNET_SERVICE_ROOT
import os
import argparse
import re
import subprocess

import StringIO
import ConfigParser
import MySQLdb

BASE_DIR = '/home/gerrit2/review_site'
GERRIT_CACHE_DIR = os.path.expanduser(os.environ.get('GERRIT_CACHE_DIR',
                                '~/.launchpadlib/cache'))
GERRIT_CREDENTIALS = os.path.expanduser(os.environ.get('GERRIT_CREDENTIALS',
                                '~/.launchpadlib/creds'))
GERRIT_CONFIG = os.environ.get('GERRIT_CONFIG',
                                 '/home/gerrit2/review_site/etc/gerrit.config')
GERRIT_SECURE_CONFIG = os.environ.get('GERRIT_SECURE_CONFIG',
                                 '/home/gerrit2/review_site/etc/secure.config')
SPEC_RE = re.compile(r'(blueprint|bp)\s*[#:]?\s*(\S+)', re.I)
BODY_RE = re.compile(r'^\s+.*$')

def get_broken_config(filename):
    """ gerrit config ini files are broken and have leading tabs """
    text = ""
    with open(filename,"r") as conf:
        for line in conf.readlines():
            text = "%s%s" % (text, line.lstrip())

    fp = StringIO.StringIO(text)
    c=ConfigParser.ConfigParser()
    c.readfp(fp)
    return c

GERRIT_CONFIG = get_broken_config(GERRIT_CONFIG)
SECURE_CONFIG = get_broken_config(GERRIT_SECURE_CONFIG)
DB_USER = GERRIT_CONFIG.get("database", "username")
DB_PASS = SECURE_CONFIG.get("database","password")
DB_DB = GERRIT_CONFIG.get("database","database")

def update_spec(launchpad, project, name, subject, link, topic=None):
    # For testing, if a project doesn't match openstack/foo, use
    # the openstack-ci project instead.
    group, project = project.split('/')
    if group != 'openstack':
        project = 'openstack-ci'

    spec = launchpad.projects[project].getSpecification(name=name)
    if not spec: return

    if spec.whiteboard:
        wb = spec.whiteboard.strip()
    else:
        wb = ''
    changed = False
    if topic:
        topiclink = '%s/#q,topic:%s,n,z' % (link[:link.find('/',8)],
                                            topic)
        if topiclink not in wb:
            wb += "\n\n\nGerrit topic: %(link)s" % dict(link=topiclink)
            changed = True

    if link not in wb:
        wb += "\n\n\nAddressed by: %(link)s\n    %(subject)s\n" % dict(subject=subject,
                                                                      link=link)
        changed = True

    if changed:
        spec.whiteboard = wb
        spec.lp_save()

def find_specs(launchpad, dbconn, args):
    git_log = subprocess.Popen(['git',
                                '--git-dir=' + BASE_DIR + '/git/' + args.project + '.git',
                                'log', '--no-merges',
                                args.commit + '^1..' + args.commit],
                               stdout=subprocess.PIPE).communicate()[0]

    cur = dbconn.cursor()
    cur.execute("select subject, topic from changes where change_key=%s", args.change)
    subject, topic = cur.fetchone()
    specs = set([m.group(2) for m in SPEC_RE.finditer(git_log)])

    if topic:
        topicspec = topic.split('/')[-1]
        specs |= set([topicspec])

    for spec in specs:
        update_spec(launchpad, args.project, spec, subject,
                    args.change_url, topic)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('hook')
    #common
    parser.add_argument('--change', default=None)
    parser.add_argument('--change-url', default=None)
    parser.add_argument('--project', default=None)
    parser.add_argument('--branch', default=None)
    parser.add_argument('--commit', default=None)
    #change-merged
    parser.add_argument('--submitter', default=None)
    # patchset-created
    parser.add_argument('--uploader', default=None)
    parser.add_argument('--patchset', default=None)

    args = parser.parse_args()

    launchpad = Launchpad.login_with('Gerrit User Sync', LPNET_SERVICE_ROOT,
                                     GERRIT_CACHE_DIR,
                                     credentials_file = GERRIT_CREDENTIALS,
                                     version='devel')

    conn = MySQLdb.connect(user = DB_USER, passwd = DB_PASS, db = DB_DB)

    find_specs(launchpad, conn, args)

if __name__ == '__main__':
    main()
