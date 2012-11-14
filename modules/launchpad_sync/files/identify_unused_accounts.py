#! /usr/bin/env python
# Copyright (C) 2011 OpenStack, LLC.
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

# Synchronize Gerrit users from Launchpad.

#SELECT account_id FROM accounts LEFT OUTER JOIN changes   ON (changes.owner_account_id = accounts.account_id)   WHERE changes.owner_account_id IS NULL;

#SELECT account_id FROM accounts LEFT OUTER JOIN change_messages   ON (change_messages.author_id = accounts.account_id)   WHERE change_messages.author_id IS NULL;

import ConfigParser
import MySQLdb
import StringIO
import os

def get_broken_config(filename):
    """ gerrit config ini files are broken and have leading tabs """
    text = ""
    with open(filename, "r") as conf:
        for line in conf.readlines():
            text = "%s%s" % (text, line.lstrip())

    fp = StringIO.StringIO(text)
    c = ConfigParser.ConfigParser()
    c.readfp(fp)
    return c

GERRIT_CONFIG = os.environ.get('GERRIT_CONFIG',
                               '/home/gerrit2/review_site/etc/gerrit.config')
GERRIT_SECURE_CONFIG = os.environ.get(
                            'GERRIT_SECURE_CONFIG',
                            '/home/gerrit2/review_site/etc/secure.config')

gerrit_config = get_broken_config(GERRIT_CONFIG)
secure_config = get_broken_config(GERRIT_SECURE_CONFIG)

DB_USER = gerrit_config.get("database", "username")
DB_PASS = secure_config.get("database", "password")
DB_DB = gerrit_config.get("database", "database")

conn = MySQLdb.connect(user=DB_USER, passwd=DB_PASS, db=DB_DB)
cur = conn.cursor()
account_ids = []
cur.execute("select distinct account_id from account_external_ids where external_id like 'http%'")
for row in cur.fetchall():
    account_ids.append(row[0])
print len(account_ids)

cur.execute("select distinct owner_account_id from changes")
for row in cur.fetchall():
    if row[0] in account_ids:
        account_ids.remove(row[0])
print len(account_ids)

cur.execute("select distinct author_id from change_messages")
for row in cur.fetchall():
    if row[0] in account_ids:
        account_ids.remove(row[0])
print len(account_ids)

cur.execute("select distinct account_id from patch_set_approvals")
for row in cur.fetchall():
    if row[0] in account_ids:
        account_ids.remove(row[0])
print len(account_ids)

cur.execute("select distinct author_id from patch_comments")
for row in cur.fetchall():
    if row[0] in account_ids:
        account_ids.remove(row[0])
print len(account_ids)

cur.execute("select distinct uploader_account_id from patch_sets")
for row in cur.fetchall():
    if row[0] in account_ids:
        account_ids.remove(row[0])
print len(account_ids)

cur.execute("select group_id from account_group_names "
            "where name='openstack-cla'")
gid = cur.fetchall()[0][0]

cur.execute("select account_id from account_group_members where group_id=%s ",
            (gid))
for row in cur.fetchall():
    if row[0] in account_ids:
        account_ids.remove(row[0])
print len(account_ids)

for account_id in account_ids:
    cur.execute("delete from account_agreements where account_id=%s",
                (account_id))
    cur.execute("delete from account_diff_preferences where id=%s",
                (account_id))
    cur.execute("delete from account_external_ids where account_id=%s",
                (account_id))
    cur.execute("delete from account_group_members where account_id=%s",
                (account_id))
    cur.execute("delete from account_group_members_audit where account_id=%s",
                (account_id))
    cur.execute("delete from account_patch_reviews where account_id=%s",
                (account_id))
    cur.execute("delete from account_project_watches where account_id=%s",
                (account_id))
    cur.execute("delete from account_ssh_keys where account_id=%s",
                (account_id))
    cur.execute("delete from accounts where account_id=%s",
                (account_id))
print len(account_ids)

groups_to_del = []
cur.execute("select * from account_group_names")
for row in cur.fetchall():
    if row[1].endswith('-core'): continue
    if row[1].endswith('-admins'): continue
    if row[1].endswith('-drivers'): continue
    if row[1] == 'openstack-cla': continue
    if row[1] == 'openstack-release': continue
    if row[1] == 'heat': continue
    if row[1][0] >= 'A' and row[1][0] <= 'Z': continue
    print 'delete group', row[1]
    groups_to_del.append(row[0])

for gid in groups_to_del:
    cur.execute("delete from account_group_includes where group_id=%s", (gid))
    cur.execute("delete from account_group_includes where include_id=%s", (gid))
    cur.execute("delete from account_group_members where group_id=%s", (gid))
    cur.execute("delete from account_group_members_audit where group_id=%s",
                (gid))
    cur.execute("delete from account_group_names where group_id=%s", (gid))
    cur.execute("delete from account_groups where group_id=%s", (gid))

conn.commit()
