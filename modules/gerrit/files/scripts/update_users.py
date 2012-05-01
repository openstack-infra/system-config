#! /usr/bin/env python
# Copyright (C) 2012 OpenStack, LLC.
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
# TODO items:
# 1. add a temporary (instance level) object store for the launchpad class
# 2. split out the two classes into separate files to be used as a library

import os
import ConfigParser
import StringIO
import paramiko
import json
import logging
import uuid
from launchpadlib.launchpad import Launchpad
from launchpadlib.uris import LPNET_SERVICE_ROOT

from datetime import datetime

from openid.consumer import consumer
from openid.cryptutil import randomString

GERRIT_USER = os.environ.get('GERRIT_USER', 'launchpadsync')
GERRIT_CONFIG = os.environ.get('GERRIT_CONFIG',
                                 '/home/gerrit2/review_site/etc/gerrit.config')
GERRIT_SECURE_CONFIG = os.environ.get('GERRIT_SECURE_CONFIG',
                                 '/home/gerrit2/review_site/etc/secure.config')
GERRIT_SSH_KEY = os.environ.get('GERRIT_SSH_KEY',
                                 '/home/gerrit2/.ssh/launchpadsync_rsa')
GERRIT_CACHE_DIR = os.path.expanduser(os.environ.get('GERRIT_CACHE_DIR',
                                '~/.launchpadlib/cache'))
GERRIT_CREDENTIALS = os.path.expanduser(os.environ.get('GERRIT_CREDENTIALS',
                                '~/.launchpadlib/creds'))
GERRIT_BACKUP_PATH = os.environ.get('GERRIT_BACKUP_PATH',
                                '/home/gerrit2/dbupdates')

logging.basicConfig(format='%(asctime)-6s: %(name)s - %(levelname)s - %(message)s', filename='/var/log/gerrit/update_users.log')
logger= logging.getLogger('update_users')
logger.setLevel(logging.INFO)

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

gerrit_config = get_broken_config(GERRIT_CONFIG)
secure_config = get_broken_config(GERRIT_SECURE_CONFIG)

DB_USER = gerrit_config.get("database", "username")
DB_PASS = secure_config.get("database","password")
DB_DB = gerrit_config.get("database","database")

def make_db_backup():
  db_backup_file = "%s.%s.sql" % (DB_DB, datetime.isoformat(datetime.now()))
  db_backup_path = os.path.join(GERRIT_BACKUP_PATH, db_backup_file)
  retval = os.system("mysqldump --opt -u%s -p%s %s > %s" %
                       (DB_USER, DB_PASS, DB_DB, db_backup_path))
  if retval != 0:
    logger.error("Problem taking a db dump, aborting db update")
    sys.exit(retval)

class LaunchpadAction(object):
  def __init__(self):
    logger.info('Connecting to Launchpad')
    self.launchpad= Launchpad.login_with('Gerrit User Sync', LPNET_SERVICE_ROOT,
                                 GERRIT_CACHE_DIR,
                                 credentials_file = GERRIT_CREDENTIALS)

    logger.info('Getting Launchpad teams')
    self.lp_teams= self.get_all_sub_teams('openstack', [])

  def get_all_sub_teams(self, team, have_teams):
    for sub_team in self.launchpad.people[team].sub_teams:
      if sub_team.name not in have_teams:
         have_teams = self.get_all_sub_teams(sub_team.name, have_teams)
    have_teams.append(team)
    return have_teams

  def get_sub_teams(self, team):
    sub_teams= []
    for sub_team in self.launchpad.people[team].sub_teams:
      sub_teams.append(sub_team.name)
    return sub_teams

  def get_teams(self):
    return self.lp_teams

  def get_all_users(self):
    logger.info('Getting Launchpad users')
    users= []
    for team in self.lp_teams:
      for detail in self.launchpad.people[team].members_details:
        if (detail.status == 'Approved' or detail.status == 'Administrator'):
          name= detail.self_link.split('/')[-1]
          if ((users.count(name) == 0) and (name not in self.lp_teams)):
            users.append(name)
    return users

  def get_user_data(self, user):
    return self.launchpad.people[user]

  def get_team_members(self, team, gerrit):
    users= []
    for detail in self.launchpad.people[team].members_details:
      if (detail.status == 'Approved' or detail.status == 'Administrator'):
        name= detail.self_link.split('/')[-1]
        # if we found a subteam
        if name in self.lp_teams:
          # check subteam for implied subteams
          for implied_group in gerrit.get_implied_groups(name):
            if implied_group in self.lp_teams:
              users.extend(self.get_team_members(implied_group, gerrit))
          users.extend(self.get_team_members(name, gerrit))
          continue
        users.append(name)
    # check team for implied teams
    for implied_group in gerrit.get_implied_groups(team):
      if implied_group in self.lp_teams:
        users.extend(self.get_team_members(implied_group, gerrit))
    # filter out dupes
    users= list(set(users))
    return users

  def get_team_watches(self, team):
    users= []
    for detail in self.launchpad.people[team].members_details:
      if (detail.status == 'Approved' or detail.status == 'Administrator'):
        name= detail.self_link.split('/')[-1]
        if name in self.lp_teams:
          continue
        if users.count(name) == 0:
          users.append(name)
    return users

  def get_team_display_name(self, team):
    team_data = self.launchpad.people[team]
    return team_data.display_name

class GerritAction(object):
  def __init__(self):
    logger.info('Connecting to Gerrit')
    self.ssh= paramiko.SSHClient()
    self.ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    self.ssh.connect('localhost', username=GERRIT_USER, port=29418, key_filename=GERRIT_SSH_KEY)

  def cleanup(self):
    logger.info('Closing connection to Gerrit')
    self.ssh.close()

  def run_query(self, query):
    command= 'gerrit gsql --format JSON -c "{0}"'.format(query)
    stdin, stdout, stderr= self.ssh.exec_command(command)
#   trying to get stdout return code or stderr can hang with large result sets
#    for line in stderr:
#      logger.error(line)
    return stdout

  def get_groups(self):
    logger.info('Getting Gerrit groups')
    groups= []
    query= "select name from account_groups"
    stdout= self.run_query(query)
    for line in stdout:
      row= json.loads(line)
      if row['type'] == 'row':
        group= row['columns']['name']
        groups.append(group)
    return groups

  def get_users(self):
    logger.info('Getting Gerrit users')
    users= []
    query= "select external_id from account_external_ids"
    stdout= self.run_query(query)
    for line in stdout:
      row= json.loads(line)
      if row['type'] == 'row':
        user= row['columns']['external_id'].replace('username:','')
        users.append(user)
    return users

  def get_group_id(self, group_name):
    query= "select group_id from account_groups where name='{0}'".format(group_name)
    stdout= self.run_query(query)
    line= stdout.readline()
    row= json.loads(line)
    if row['type'] == 'row':
      return row['columns']['group_id']
    else:
      return 0

  def get_user_id(self, user_name):
    query= "select account_id from account_external_ids where external_id='username:{0}'".format(user_name)
    stdout= self.run_query(query)
    line= stdout.readline()
    row= json.loads(line)
    return row['columns']['account_id']

  def get_users_from_group(self, group_name):
    logger.info('Getting Gerrit users from group %s', group_name)
    users= []
    gid= self.get_group_id(group_name)

    query= "select external_id from account_external_ids join account_group_members on account_group_members.account_id=account_external_ids.account_id where account_group_members.group_id={0} and external_id like 'username%%'".format(gid)
    stdout= self.run_query(query)
    for line in stdout:
      row= json.loads(line)
      if row['type'] == 'row':
        user= row['columns']['external_id'].replace('username:','')
        users.append(user)
    return users

  def get_users_from_watches(self, group_name):
    logger.info('Getting Gerrit users from watch list %s', group_name)
    users= []
    if group_name.endswith("-core"):
      group_name = group_name[:-5]
    group_name = "openstack/{0}".format(group_name)

    query= "select external_id from account_external_ids join account_project_watches on account_project_watches.account_id=account_external_ids.account_id where account_project_watches.project_name like '{0}' and external_id like 'username%%'".format(group_name)
    stdout= self.run_query(query)
    for line in stdout:
      row= json.loads(line)
      if row['type'] == 'row':
        user= row['columns']['external_id'].replace('username:','')
        users.append(user)
    return users


  def get_implied_groups(self, group_name):
    gid= self.get_group_id(group_name)
    groups= []
    query= "select name from account_groups join account_group_includes on account_group_includes.include_id=account_groups.group_id where account_group_includes.group_id={0}".format(gid)
    stdout= self.run_query(query)
    for line in stdout:
      row= json.loads(line)
      if row['type'] == 'row':
        group= row['columns']['name']
        groups.append(group)
    return groups

  def add_group(self, group_name, group_display_name):
    logger.info('New group %s (%s)', group_display_name, group)
    query= "insert into account_group_id (s) values (NULL)"
    stdout= self.run_query(query)
    row= json.loads(stdout.readline())
    if row['rowCount'] is not 1:
      print "Could not get a new account group ID"
      raise
    query= "select max(s) from account_group_id"
    stdout= self.run_query(query)
    row= json.loads(stdout.readline())
    gid= row['columns']['max(s)']
    full_uuid= "{0}{1}".format(uuid.uuid4().hex, uuid.uuid4().hex[:8])
    query= "insert into account_groups (group_id, group_type, owner_group_id, name, description, group_uuid) values ({0}, 'INTERNAL', 1, '{1}', '{2}', '{3}')". format(gid, group_name, group_display_name, full_uuid)
    self.run_query(query)
    query= "insert into account_group_names (group_id, name) values ({0}, '{1}')".format(gid, group_name)
    self.run_query(query)

  def add_user(self, user_name, user_data):
    logger.info("Adding Gerrit user %s", user_name)
    openid_consumer = consumer.Consumer(dict(id=randomString(16, '0123456789abcdef')), None)
    openid_request = openid_consumer.begin("https://launchpad.net/~%s" % user_data.name)
    user_openid_external_id = openid_request.endpoint.getLocalID()
    query= "select account_id from account_external_ids where external_id in ('{0}')".format(user_openid_external_id)
    stdout= self.run_query(query)
    row= json.loads(stdout.readline())
    if row['type'] == 'row':
      # we have a result so this is an updated user name
      account_id= row['columns']['account_id']
      query= "update account_external_ids set external_id='{0}' where external_id like 'username%%' and account_id = {1}".format('username:%s' % user_name, account_id)
      self.run_query(query)
    else:
      # we really do have a new user
      user_ssh_keys= ["%s %s %s" % ('ssh-%s' % key.keytype.lower(), key.keytext, key.comment) for key in user_data.sshkeys]
      user_email= None
      try:
        email = user_data.preferred_email_address.email
      except ValueError:
        pass
      query= "insert into account_id (s) values (NULL)"
      self.run_query(query)
      query= "select max(s) from account_id"
      stdout= self.run_query(query)
      row= json.loads(stdout.readline())
      uid= row['columns']['max(s)']
      query= "insert into accounts (account_id, full_name, preferred_email) values ({0}, '{1}', '{2}')".format(uid, user_name, user_email)
      self.run_query(query)
      keyno= 1
      for key in user_ssh_keys:
        query= "insert into account_ssh_keys (ssh_public_key, valid, account_id, seq) values ('{0}', 'Y', {1}, {2})".format(key.strip(), uid, keyno)
        self.run_query(query)
        keyno = keyno + 1
      query= "insert into account_external_ids (account_id, email_address, external_id) values ({0}, '{1}', '{2}')".format(uid, user_email, user_openid_external_id)
      self.run_query(query)
      query= "insert into account_external_ids (account_id, external_id) values ({0}, '{1}')".format(uid, "username:%s" % user_name)
      self.run_query(query)
      if user_email is not None:
        query= "insert into account_external_ids (account_id, email_address, external_id) values ({0}. '{1}', '{2}')".format(uid, user_email, "mailto:%s" % user_email)
    return None

  def add_user_to_group(self, user_name, group_name):
    logger.info("Adding Gerrit user %s to group %s", user_name, group_name)
    uid= self.get_user_id(user_name)
    gid= self.get_group_id(group_name)
    if gid is 0:
      print "Trying to add user {0} to non-existent group {1}".format(user_name, group_name)
      raise
    query= "insert into account_group_members (account_id, group_id) values ({0}, {1})".format(uid, gid)
    self.run_query(query)

  def add_user_to_watch(self, user_name, group_name):
    logger.info("Adding Gerrit user %s to watch group %s", user_name, group_name)
    uid= self.get_user_id(user_name)
    if group_name.endswith("-core"):
      group_name = group_name[:-5]
    group_name = "openstack/{0}".format(group_name)
    query= "insert into account_project_watches VALUES ('Y', 'N', 'N', {0}, '{1}', '*')". format(uid, group_name)
    self.run_query(query)


  def del_user_from_group(self, user_name, group_name):
    logger.info("Deleting Gerrit user %s from group %s", user_name, group_name)
    uid= self.get_user_id(user_name)
    gid= self.get_group_id(group_name)
    query= "delete from account_group_members where account_id = {0} and group_id = {1}".format(uid, gid)
    self.run_query(query)
    if group_name.endswith("-core"):
      group_name = group_name[:-5]
    group_name= "openstack/{0}".format(group_name)
    query= "delete from account_project_watches where account_id = {0} and project_name= '{1}'".format(uid, group_name)
    self.run_query(query)

  def rebuild_sub_groups(self, group, sub_groups):
    gid= self.get_group_id(group)
    for sub_group in sub_groups:
      sgid= self.get_group_id(sub_group)
      query= "select group_id from account_group_includes where group_id={0} and include_id={1}".format(gid, sgid)
      stdout= self.run_query(query)
      row= json.loads(stdout.readline())
      if row['type'] != 'row':
        logger.info('Adding implied group %s to group %s', group, sub_group)
        query= "insert into account_group_includes (group_id, include_id) values ({0}, {1})".format(gid, sgid)
        self.run_query(query)


# Actual work starts here!

lp= LaunchpadAction()
gerrit= GerritAction()

logger.info('Making DB backup')
make_db_backup()

logger.info('Starting group reconcile')
lp_groups= lp.get_teams()
gerrit_groups= gerrit.get_groups()

group_diff= filter(lambda a: a not in gerrit_groups, lp_groups)
for group in group_diff:
  group_display_name= lp.get_team_display_name(group)
  gerrit.add_group(group, group_display_name)

for group in lp_groups:
  sub_group= lp.get_sub_teams(group)
  if sub_group:
    gerrit.rebuild_sub_groups(group, sub_group)

logger.info('End group reconcile')

logger.info('Starting user reconcile')
lp_users= lp.get_all_users()
gerrit_users= gerrit.get_users()

user_diff= filter(lambda a: a not in gerrit_users, lp_users)
for user in user_diff:
  gerrit.add_user(user, lp.get_user_data(user))

logger.info('End user reconcile')

logger.info('Starting user to group reconcile')
lp_groups= lp.get_teams()
for group in lp_groups:
  # First find users to attach to groups
  gerrit_group_users= gerrit.get_users_from_group(group)
  lp_group_users= lp.get_team_members(group, gerrit)

  group_diff= filter(lambda a: a not in gerrit_group_users, lp_group_users)
  for user in group_diff:
    gerrit.add_user_to_group(user, group)
  # Second find users to attach to watches
  lp_group_watches= lp.get_team_watches(group)
  gerrit_group_watches= gerrit.get_users_from_watches(group)
  group_diff= filter(lambda a: a not in gerrit_group_watches, lp_group_watches)
  for user in group_diff:
    gerrit.add_user_to_watch(user, group)
  # Third find users to remove from groups/watches
  group_diff= filter(lambda a: a not in lp_group_users, gerrit_group_users)
  for user in group_diff:
    gerrit.del_user_from_group(user, group)

logger.info('Ending user to group reconcile')

gerrit.cleanup()
