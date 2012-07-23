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

import os
import sys
import fcntl
import uuid
import subprocess

from datetime import datetime

# There is a bug (810019) somewhere deep which causes pkg_resources
# to bitch if it's imported after argparse. launchpadlib imports it,
# so if we head it off at the pass, we can skip cronspam
import pkg_resources

import StringIO
import ConfigParser
import argparse
import MySQLdb

from launchpadlib.launchpad import Launchpad
from launchpadlib.uris import LPNET_SERVICE_ROOT

from openid.consumer import consumer
from openid.cryptutil import randomString

DEBUG = False

# suppress pyflakes
pkg_resources.get_supported_platform()

pid_file = '/tmp/update_gerrit_users.pid'
fp = open(pid_file, 'w')
try:
    fcntl.lockf(fp, fcntl.LOCK_EX | fcntl.LOCK_NB)
except IOError:
    # another instance is running
    sys.exit(0)

parser = argparse.ArgumentParser()
parser.add_argument('user', help='The gerrit admin user')
parser.add_argument('ssh_key', help='The gerrit admin SSH key file')
parser.add_argument('site', help='The site in use (typically openstack or stackforge)')
options = parser.parse_args()

GERRIT_USER = options.user
GERRIT_CONFIG = os.environ.get('GERRIT_CONFIG',
                                 '/home/gerrit2/review_site/etc/gerrit.config')
GERRIT_SECURE_CONFIG = os.environ.get('GERRIT_SECURE_CONFIG',
                                 '/home/gerrit2/review_site/etc/secure.config')
GERRIT_SSH_KEY = options.ssh_key
GERRIT_CACHE_DIR = os.path.expanduser(os.environ.get('GERRIT_CACHE_DIR',
                                '~/.launchpadlib/cache'))
GERRIT_CREDENTIALS = os.path.expanduser(os.environ.get('GERRIT_CREDENTIALS',
                                '~/.launchpadlib/creds'))
GERRIT_BACKUP_PATH = os.environ.get('GERRIT_BACKUP_PATH',
                                '/home/gerrit2/dbupdates')

for check_path in (os.path.dirname(GERRIT_CACHE_DIR),
                   os.path.dirname(GERRIT_CREDENTIALS),
                   GERRIT_BACKUP_PATH):
  if not os.path.exists(check_path):
    os.makedirs(check_path)

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

def get_type(in_type):
  if in_type == "RSA":
    return "ssh-rsa"
  else:
    return "ssh-dsa"

gerrit_config = get_broken_config(GERRIT_CONFIG)
secure_config = get_broken_config(GERRIT_SECURE_CONFIG)

DB_USER = gerrit_config.get("database", "username")
DB_PASS = secure_config.get("database","password")
DB_DB = gerrit_config.get("database","database")

db_backup_file = "%s.%s.sql" % (DB_DB, datetime.isoformat(datetime.now()))
db_backup_path = os.path.join(GERRIT_BACKUP_PATH, db_backup_file)
retval = os.system("mysqldump --opt -u%s -p%s %s | gzip -9 > %s.gz" %
                     (DB_USER, DB_PASS, DB_DB, db_backup_path))
if retval != 0:
  print "Problem taking a db dump, aborting db update"
  sys.exit(retval)

conn = MySQLdb.connect(user = DB_USER, passwd = DB_PASS, db = DB_DB)
cur = conn.cursor()


launchpad = Launchpad.login_with('Gerrit User Sync', LPNET_SERVICE_ROOT,
                                 GERRIT_CACHE_DIR,
                                 credentials_file = GERRIT_CREDENTIALS)

def get_sub_teams(team, have_teams):
    for sub_team in launchpad.people[team].sub_teams:
        if sub_team.name not in have_teams:
           have_teams = get_sub_teams(sub_team.name, have_teams)
    have_teams.append(team)
    return have_teams


teams_todo = get_sub_teams('openstack', [])

users={}
groups={}
groups_in_groups={}
group_implies_groups={}
group_ids={}
projects = subprocess.check_output(['/usr/bin/ssh', '-p', '29418',
    '-i', GERRIT_SSH_KEY,
    '-l', GERRIT_USER, 'localhost',
    'gerrit', 'ls-projects']).split('\n')

for team_todo in teams_todo:

  team = launchpad.people[team_todo]
  groups[team.name] = team.display_name

  # Attempt to get nested group memberships. ~nova-core, for instance, is a
  # member of ~nova, so membership in ~nova-core should imply membership in
  # ~nova
  group_in_group = groups_in_groups.get(team.name, {})
  for subgroup in team.sub_teams:
    group_in_group[subgroup.name] = 1
  # We should now have a dictionary of the form {'nova': {'nova-core': 1}}
  groups_in_groups[team.name] = group_in_group

  for detail in team.members_details:

    user = None

    # detail.self_link ==
    # 'https://api.launchpad.net/1.0/~team/+member/${username}'
    login = detail.self_link.split('/')[-1]

    if users.has_key(login):
      user = users[login]
    else:

      user = dict(add_groups=[])

    status = detail.status
    if (status == "Approved" or status == "Administrator"):
      user['add_groups'].append(team.name)
    users[login] = user

# If we picked up subgroups that were not in our original list of groups
# make sure they get added
for (supergroup, subgroups) in groups_in_groups.items():
  for group in subgroups.keys():
    if group not in groups.keys():
      groups[group] = None

# account_groups
# groups is a dict of team name to team display name
# here, for every group we have in that dict, we're building another dict of
# group_name to group_id - and if the database doesn't already have the
# group, we're adding it
for (group_name, group_display_name) in groups.items():
  if cur.execute("select group_id from account_groups where name = %s",
                 group_name):
    group_ids[group_name] = cur.fetchall()[0][0]
  else:
    cur.execute("""insert into account_group_id (s) values (NULL)""");
    cur.execute("select max(s) from account_group_id")
    group_id = cur.fetchall()[0][0]

    # Match the 40-char 'uuid' that java is producing
    group_uuid = uuid.uuid4()
    second_uuid = uuid.uuid4()
    full_uuid = "%s%s" % (group_uuid.hex, second_uuid.hex[:8])

    cur.execute("""insert into account_groups
                   (group_id, group_type, owner_group_id,
                    name, description, group_uuid)
                   values
                   (%s, 'INTERNAL', 1, %s, %s, %s)""",
                (group_id, group_name, group_display_name, full_uuid))
    cur.execute("""insert into account_group_names (group_id, name) values
    (%s, %s)""",
    (group_id, group_name))

    group_ids[group_name] = group_id

# account_group_includes
# groups_in_groups should be a dict of dicts, where the key is the larger
# group and the inner dict is a list of groups that are members of the
# larger group. So {'nova': {'nova-core': 1}}
for (group_name, subgroups) in groups_in_groups.items():
  for subgroup_name in subgroups.keys():
    try:
      cur.execute("""insert into account_group_includes
                       (group_id, include_id)
                      values (%s, %s)""",
                  (group_ids[group_name], group_ids[subgroup_name]))
    except MySQLdb.IntegrityError:
      pass

# Make a list of implied group membership
# building a list which is the opposite of groups_in_group. Here
# group_implies_groups is a dict keyed by group_id containing a list of
# group_ids of implied membership. SO: if nova is 1 and nova-core is 2:
# {'2': [1]}
for group_id in group_ids.values():
    total_groups = []
    groups_todo = [group_id]
    while len(groups_todo) > 0:
        current_group = groups_todo.pop()
        total_groups.append(current_group)
        cur.execute("""select group_id from account_group_includes
                        where include_id = %s""", (current_group))
        for row in cur.fetchall():
            if row[0] != 1 and row[0] not in total_groups:
                groups_todo.append(row[0])
    group_implies_groups[group_id] = total_groups

if DEBUG:
    def get_group_name(in_group_id):
      for (group_name, group_id) in group_ids.items():
        if group_id == in_group_id:
          return group_name

    print "groups in groups"
    for (k,v) in groups_in_groups.items():
      print k, v

    print "group_imples_groups"
    for (k, v) in group_implies_groups.items():
      print get_group_name(k)
      new_groups=[]
      for val in v:
        new_groups.append(get_group_name(val))
      print "\t", new_groups

for (username, user_details) in users.items():
  member = launchpad.people[username]
  # accounts
  account_id = None
  if cur.execute("""select account_id from account_external_ids where
    external_id in (%s)""", ("username:%s" % username)):
    account_id = cur.fetchall()[0][0]
    # We have this bad boy - all we need to do is update his group membership

  else:
    # We need details
    if not member.is_team:

      openid_consumer = consumer.Consumer(dict(id=randomString(16, '0123456789abcdef')), None)
      openid_request = openid_consumer.begin("https://launchpad.net/~%s" % member.name)
      user_details['openid_external_id'] = openid_request.endpoint.getLocalID()

      # Handle username change
      if cur.execute("""select account_id from account_external_ids where
        external_id in (%s)""", user_details['openid_external_id']):
        account_id = cur.fetchall()[0][0]
        cur.execute("""update account_external_ids
                          set external_id=%s
                        where external_id like 'username%%'
                          and account_id = %s""",
                     ('username:%s' % username, account_id))
      else:
        email = None
        try:
          email = member.preferred_email_address.email
        except ValueError:
          pass
        user_details['email'] = email


        cur.execute("""insert into account_id (s) values (NULL)""");
        cur.execute("select max(s) from account_id")
        account_id = cur.fetchall()[0][0]

        cur.execute("""insert into accounts (account_id, full_name, preferred_email) values
        (%s, %s, %s)""", (account_id, username, user_details['email']))

        # account_external_ids
        ## external_id
        if not cur.execute("""select account_id from account_external_ids
                              where account_id = %s and external_id = %s""",
                           (account_id, user_details['openid_external_id'])):
          cur.execute("""insert into account_external_ids
                         (account_id, email_address, external_id)
                         values (%s, %s, %s)""",
                     (account_id, user_details['email'], user_details['openid_external_id']))
        if not cur.execute("""select account_id from account_external_ids
                              where account_id = %s and external_id = %s""",
                           (account_id, "username:%s" % username)):
          cur.execute("""insert into account_external_ids
                         (account_id, external_id) values (%s, %s)""",
                      (account_id, "username:%s" % username))

        if user_details.get('email', None) is not None:
          if not cur.execute("""select account_id from account_external_ids
                                where account_id = %s and external_id = %s""",
                             (account_id, "mailto:%s" % user_details['email'])):
            cur.execute("""insert into account_external_ids
                           (account_id, email_address, external_id)
                           values (%s, %s, %s)""",
                        (account_id, user_details['email'], "mailto:%s" %
                        user_details['email']))

  if account_id is not None:
    # account_ssh_keys
    user_details['ssh_keys'] = ["%s %s %s" % (get_type(key.keytype), key.keytext, key.comment) for key in member.sshkeys]

    for key in user_details['ssh_keys']:

      cur.execute("""select ssh_public_key from account_ssh_keys where
        account_id = %s""", account_id)
      db_keys = [r[0].strip() for r in cur.fetchall()]
      if key.strip() not in db_keys:

        cur.execute("""select max(seq)+1 from account_ssh_keys
                              where account_id = %s""", account_id)
        seq = cur.fetchall()[0][0]
        if seq is None:
          seq = 1
        cur.execute("""insert into account_ssh_keys
                        (ssh_public_key, valid, account_id, seq)
                        values
                        (%s, 'Y', %s, %s)""",
                        (key.strip(), account_id, seq))

    # account_group_members
    # user_details['add_groups'] is a list of group names for which the
    # user is either "Approved" or "Administrator"

    groups_to_add = []
    groups_to_watch = {}
    groups_to_rm = {}

    for group in user_details['add_groups']:
      # if you are in the group nova-core, that should also put you in nova
      add_groups = group_implies_groups[group_ids[group]]
      add_groups.append(group_ids[group])
      for add_group in add_groups:
        if add_group not in groups_to_add:
          groups_to_add.append(add_group)
      # We only want to add watches for direct project membership groups
      groups_to_watch[group_ids[group]] = group

    # groups_to_add is now the full list of all groups we think the user
    # should belong to. we want to limit the users groups to this list
    for group in groups:
      if group_ids[group] not in groups_to_add:
        if group not in groups_to_rm.values():
          groups_to_rm[group_ids[group]] = group

    for group_id in groups_to_add:
      if not cur.execute("""select account_id from account_group_members
                            where account_id = %s and group_id = %s""",
                         (account_id, group_id)):
        # The current user does not exist in the group. Add it.
        cur.execute("""insert into account_group_members
                         (account_id, group_id)
                       values (%s, %s)""", (account_id, group_id))
        os_project_name = groups_to_watch.get(group_id, None)
        if os_project_name is not None:
          if os_project_name.endswith("-core"):
              os_project_name = os_project_name[:-5]
          os_project_name = "{site}/{project}".format(site=options.site, project=os_project_name)
          if os_project_name in projects:
            if not cur.execute("""select account_id
                                   from account_project_watches
                                  where account_id = %s
                                    and project_name = %s""",
                                 (account_id, os_project_name)):
                cur.execute("""insert into account_project_watches
                               VALUES
                               ("Y", "N", "N", %s, %s, "*")""",
                               (account_id, os_project_name))

    for (group_id, group_name) in groups_to_rm.items():
      cur.execute("""delete from account_group_members
                     where account_id = %s and group_id = %s""",
                  (account_id, group_id))

os.system("ssh -i %s -p29418 %s@localhost gerrit flush-caches" %
          (GERRIT_SSH_KEY, GERRIT_USER))

conn.commit()
