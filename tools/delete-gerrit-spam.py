# Copyright 2016 Red Hat, Inc.
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

import MySQLdb
import ConfigParser
from prettytable import PrettyTable
import argparse

parser = argparse.ArgumentParser(description=
                                 'Delete spam comments from Gerrit.')
parser.add_argument('account_id',
                    help='The numeric account id of the spammer')
parser.add_argument('--delete', action='store_true',
                    help='actually perform the deletion (the default'
                    'behavior is a dry run)')
args = parser.parse_args()

config = ConfigParser.RawConfigParser()
config.read('/root/.my.cnf')
host = config.get('client', 'host')
user = config.get('client', 'user')
pw = config.get('client', 'password')

db = MySQLdb.connect(host=host, user=user, passwd=pw, db='reviewdb')
cur = db.cursor()

potential_parents = set()
t = PrettyTable(['Change', 'Patchset', 'File', 'UUID', 'Date', 'Message'])
t.align = 'l'
cur.execute('select change_id, patch_set_id, file_name, uuid, written_on, '
            'message from patch_comments where author_id=%s', args.account_id)
for row in cur.fetchall():
    t.add_row(row)
    potential_parents.add(row[3])
if cur.rowcount:
    print "Patch Comments -- To Be Deleted"
    print t
    if args.delete:
        cur.execute('delete from patch_comments where author_id=%s',
                    args.account_id)

if potential_parents:
    placeholders = ','.join(['%s'] * len(potential_parents))
    query = ('select change_id, patch_set_id, file_name, uuid, written_on, '
             'message from patch_comments where parent_uuid in (%s)' %
             placeholders)
    cur.execute(query, list(potential_parents))
    t = PrettyTable(['Change', 'Patchset', 'File', 'UUID', 'Date', 'Message'])
    t.align = 'l'
    delete_rows = []
    for row in cur.fetchall():
        t.add_row(row)
        delete_rows.append(row)
    if cur.rowcount:
        print "Patch Comment Children -- To Be Reparented"
        print t
        if args.delete:
            for change_id, patch_set_id, file_name, uuid in delete_rows:
                cur.execute('update patch_comments set parent_uuid=NULL where '
                            'change_id=%s and patch_set_id=%s and '
                            'file_name=%s and uuid=%s',
                            change_id, patch_set_id, file_name, uuid)

t = PrettyTable(['Change', 'UUID', 'Date', 'Message'])
t.align = 'l'
cur.execute('select change_id, uuid, written_on, message from change_messages '
            'where author_id=%s', args.account_id)
for row in cur.fetchall():
    t.add_row(row)
if cur.rowcount:
    print "Change Messages -- To Be Deleted"
    print t
    if args.delete:
        cur.execute('delete from change_messages where author_id=%s',
                    args.account_id)
