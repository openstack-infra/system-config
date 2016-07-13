#!/usr/bin/env python
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

# First, display / delete patch comments.
t = PrettyTable(['Change', 'Patchset', 'File', 'UUID', 'Date', 'Message'])
t.align = 'l'
cur.execute('select change_id, patch_set_id, file_name, uuid, written_on, '
            'message from patch_comments where author_id=%s', args.account_id)
# Any of the patch comments we delete might also be a parent of some
# other comment.  Keep track of the UUID of the comments we delete and
# check later to see if they are parents.
potential_parents = set()
for row in cur.fetchall():
    t.add_row(row)
    potential_parents.add(row[3])
if cur.rowcount:
    print "Patch Comments -- To Be Deleted"
    print t
    if args.delete:
        cur.execute('delete from patch_comments where author_id=%s',
                    args.account_id)
        print "Deleted %s rows." % cur.rowcount

# If we are deleting some patch comments above, see if any of them are
# parents of other comments.  If so, unparent the child comments so
# that they don't have a 'parent_uuid' field pointing to a nonexistent
# entry.
if potential_parents:
    # This query formatting is so that we can let the client library
    # substitute the value for each member of the UUID set we created
    # above.
    placeholders = ','.join(['%s'] * len(potential_parents))
    query = ('select change_id, patch_set_id, file_name, uuid, written_on, '
             'message from patch_comments where parent_uuid in (%s)' %
             placeholders)
    cur.execute(query, list(potential_parents))
    t = PrettyTable(['Change', 'Patchset', 'File', 'UUID', 'Date', 'Message'])
    t.align = 'l'
    for row in cur.fetchall():
        t.add_row(row)
    if cur.rowcount:
        print "Patch Comment Children -- To Be Unparented"
        print t
        if args.delete:
            query = ('update patch_comments set parent_uuid=NULL where '
                     'parent_uuid in (%s)' % placeholders)
            cur.execute(query, list(potential_parents))
            print "Updated %s rows." % cur.rowcount

# Finally, display / delete any change messages.
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
        print "Deleted %s rows." % cur.rowcount
db.commit()
