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


import fcntl
import logging
import logging.config
import os
import subprocess
import sys
import uuid
import cPickle as pickle

from datetime import datetime

# There is a bug (810019) somewhere deep which causes pkg_resources
# to bitch if it's imported after argparse. launchpadlib imports it,
# so if we head it off at the pass, we can skip cronspam
import pkg_resources

import argparse
import ConfigParser
import MySQLdb
import StringIO

from launchpadlib.launchpad import Launchpad
from launchpadlib.uris import LPNET_SERVICE_ROOT

from openid.consumer import consumer
from openid.cryptutil import randomString

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
parser.add_argument('log_config', default=None, nargs='?',
                    help='Path to file containing logging config')
parser.add_argument('--prep-only', action='store_true')
parser.add_argument('--skip-prep', action='store_true')
parser.add_argument('--skip-dump', action='store_true')
parser.add_argument('-d', action='store_true')

options = parser.parse_args()

GERRIT_USER = options.user
GERRIT_CONFIG = os.environ.get('GERRIT_CONFIG',
                               '/home/gerrit2/review_site/etc/gerrit.config')
GERRIT_SECURE_CONFIG = os.environ.get(
                            'GERRIT_SECURE_CONFIG',
                            '/home/gerrit2/review_site/etc/secure.config')
GERRIT_SSH_KEY = options.ssh_key
GERRIT_CACHE_DIR = os.path.expanduser(os.environ.get('GERRIT_CACHE_DIR',
                                                     '~/.launchpadlib/cache'))
GERRIT_CREDENTIALS = os.path.expanduser(os.environ.get(
                                            'GERRIT_CREDENTIALS',
                                            '~/.launchpadlib/creds'))
GERRIT_BACKUP_PATH = os.environ.get('GERRIT_BACKUP_PATH',
                                    '/home/gerrit2/dbupdates')


def setup_logging():
    if options.log_config:
        fp = os.path.expanduser(options.log_config)
        if not os.path.exists(fp):
            raise Exception("Unable to read logging config file at %s" % fp)
        logging.config.fileConfig(fp)
    else:
        if options.d:
            logging.basicConfig(level=logging.DEBUG)
        else:
            logging.basicConfig(level=logging.INFO)

setup_logging()
log = logging.getLogger('gerrit_user_sync')
log.info('Gerrit user sync start ' + str(datetime.now()))

if not options.skip_dump:
    for check_path in (os.path.dirname(GERRIT_CACHE_DIR),
                       os.path.dirname(GERRIT_CREDENTIALS),
                       GERRIT_BACKUP_PATH):
        if not os.path.exists(check_path):
            log.info('mkdir ' + check_path)
            os.makedirs(check_path)


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


def get_type(in_type):
    if in_type == "RSA":
        return "ssh-rsa"
    else:
        return "ssh-dsa"

gerrit_config = get_broken_config(GERRIT_CONFIG)
secure_config = get_broken_config(GERRIT_SECURE_CONFIG)

DB_USER = gerrit_config.get("database", "username")
DB_PASS = secure_config.get("database", "password")
DB_DB = gerrit_config.get("database", "database")

db_backup_file = "%s.%s.sql" % (DB_DB, datetime.isoformat(datetime.now()))
db_backup_path = os.path.join(GERRIT_BACKUP_PATH, db_backup_file)
if not options.skip_dump:
    log.info('Backup mysql DB to ' + db_backup_path)
    retval = os.system("mysqldump --opt -u%s -p%s %s | gzip -9 > %s.gz" %
                       (DB_USER, DB_PASS, DB_DB, db_backup_path))
    if retval != 0:
        print "Problem taking a db dump, aborting db update"
        sys.exit(retval)

log.info('Connect to mysql DB')
conn = MySQLdb.connect(user=DB_USER, passwd=DB_PASS, db=DB_DB)
cur = conn.cursor()

log.info('Connecting to launchpad')
launchpad = Launchpad.login_with('Gerrit User Sync', LPNET_SERVICE_ROOT,
                                 GERRIT_CACHE_DIR,
                                 credentials_file=GERRIT_CREDENTIALS,
                                 version='devel')
log.info('Connected to launchpad')


class Group(object):
    def __init__(self, name, id):
        self.name = name
        self.id = id

class Team(object):
    def __init__(self, name, display_name):
        self.name = name
        self.display_name = display_name
        self.members = []
        self.sub_teams = []

class LPUser(object):
    def __init__(self, name):
        self.name = name
        self.display_name = None
        self.email = None
        self.ssh_keys = []
        self.teams = []
        self.openids = []

class GerritUser(object):
    def __init__(self, id):
        self.id = id
        self.name = None
        self.emails = []
        self.openids = []

class Sync(object):
    def __init__(self):
        self.log = logging.getLogger('sync')
        self.cursor = cur
        self.teams = {}
        self.lp_users = {}
        self.openids = {}
        self.gerrit_users = {}
        self.groups = {}

    def __getstate__(self):
        d = self.__dict__.copy()
        del d['log']
        del d['cursor']
        return d

    def __setstate__(self, state):
        self.__dict__ = state
        self.log = logging.getLogger('sync')
        self.cursor = cur

    def getProjectList(self):
        self.log.info('Listing projects')
        if options.skip_dump:
            projects = [
                'heat-api/heat',
                'heat-api/python-heatclient',
                'openstack-ci/devstack-gate',
                'openstack-ci/gerrit',
                'openstack-ci/gerrit-verification-status-plugin',
                'openstack-ci/gerritbot',
                'openstack-ci/gerritlib',
                'openstack-ci/git-review',
                'openstack-ci/jeepyb',
                'openstack-ci/jenkins-job-builder',
                'openstack-ci/lodgeit',
                'openstack-ci/meetbot',
                'openstack-ci/nose-html-output',
                'openstack-ci/puppet-apparmor',
                'openstack-ci/puppet-dashboard',
                'openstack-ci/puppet-vcsrepo',
                'openstack-ci/pypi-mirror',
                'openstack-ci/zuul',
                'openstack-dev/devstack',
                'openstack-dev/openstack-nose',
                'openstack-dev/openstack-qa',
                'openstack-dev/pbr',
                'openstack-dev/sandbox',
                'openstack/api-site',
                'openstack/ceilometer',
                'openstack/cinder',
                'openstack/compute-api',
                'openstack/glance',
                'openstack/horizon',
                'openstack/identity-api',
                'openstack/image-api',
                'openstack/keystone',
                'openstack/melange',
                'openstack/netconn-api',
                'openstack/nova',
                'openstack/object-api',
                'openstack/openstack-chef',
                'openstack/openstack-ci',
                'openstack/openstack-ci-puppet',
                'openstack/openstack-manuals',
                'openstack/openstack-planet',
                'openstack/openstack-puppet',
                'openstack/oslo-incubator',
                'openstack/python-cinderclient',
                'openstack/python-glanceclient',
                'openstack/python-keystoneclient',
                'openstack/python-melangeclient',
                'openstack/python-novaclient',
                'openstack/python-openstackclient',
                'openstack/python-quantumclient',
                'openstack/python-swiftclient',
                'openstack/quantum',
                'openstack/requirements',
                'openstack/swift',
                'openstack/tempest',
                'openstack/volume-api',
                'stackforge/MRaaS',
                'stackforge/bufunfa',
                'stackforge/diskimage-builder',
                'stackforge/libra',
                'stackforge/marconi',
                'stackforge/moniker',
                'stackforge/python-monikerclient',
                'stackforge/python-reddwarfclient',
                'stackforge/reddwarf',
                'stackforge/reddwarf-integration',
                ]
        else:
            projects = subprocess.check_output(['/usr/bin/ssh', '-p', '29418',
                                                '-i', GERRIT_SSH_KEY,
                                                '-l', GERRIT_USER, 'localhost',
                                                'gerrit', 'ls-projects'])
            projects = projects.split('\n')
        self.projects = projects

    def getGroups(self):
        self.log.info('Listing groups')
        self.groups = {}
        self.cursor.execute("select group_id, name from account_groups")
        for row in self.cursor.fetchall():
            id, name = row
            self.groups[name] = Group(name, id)

    def getOpenID(self, openid):
        person = launchpad.people.getByOpenIDIdentifier(identifier=openid)
        if not person:
            return
        lp_user = self.lp_users.get(person)
        if not lp_user:
            lp_user = LPUser(person.name)
            self.lp_users[person.name] = lp_user
        if openid not in lp_user.openids:
            lp_user.openids.append(openid)
        self.openids[openid] = lp_user

    def getGerritUsers(self):
        # Get a list of gerrit users and external ids
        log.info('Getting gerrit users')
        cur.execute("""select account_id, external_id
                       from account_external_ids""")
        rows = cur.fetchall()
        for i, row in enumerate(rows):
            account_id = row[0]
            if account_id in self.gerrit_users:
                g_user = self.gerrit_users[account_id]
            else:
                g_user = GerritUser(account_id)
                self.gerrit_users[account_id] = g_user
            if row[1].startswith('mailto:'):
                g_user.emails.append(row[1][len('mailto:'):])
            elif row[1].startswith('username:'):
                g_user.name = row[1][len('username:'):]
            else:
                g_user.openids.append(row[1])
                self.getOpenID(row[1])

    def prep(self):
        self.getProjectList()
        self.getGroups()
        self.getTeams()
        self.getLPUsers()
        self.getGerritUsers()

    def fixOpenIDs(self):
        for g_user in self.gerrit_users.values()[:]:
            account_names = {}
            for openid in g_user.openids:
                lp_user = self.openids.get(openid)
                if not lp_user:
                    continue
                account_names[lp_user.name] = openid
            if len(account_names.keys()) == 0:
                continue
            elif len(account_names.keys()) == 1:
                if account_names.keys()[0] != g_user.name:
                    self.renameAccount(g_user, account_names.keys()[0])
            else:
                for openid in g_user.openids:
                    lp_user = self.openids[openid]
                    if lp_user.name != g_user.name:
                        other_id = self.getGerritAccountID(lp_user.name)
                        other_g_user = self.gerrit_users.get(other_id)
                        if other_g_user:
                            self.moveOpenID(g_user, other_g_user, openid)
                        else:
                            self.removeOpenID(g_user, openid)

    def getGerritAccountID(self, name):
        if self.cursor.execute("""select account_id from account_external_ids
            where external_id=%s""",
                            ("username:%s" % name)):
            return self.cursor.fetchall()[0][0]
        return None

    def renameAccount(self, g_user, name):
        log.info('Rename %s %s to %s' % (g_user.name, g_user.id, name))
        # if other account exists, move openids and delete username
        # else, change username
        other_id = self.getGerritAccountID(name)
        if not other_id:
            # update external ids username:
            if g_user.name:
                log.debug('Update external_id %s: %s -> %s' % (
                        g_user.id, name, g_user.name))
                self.cursor.execute("""update account_external_ids
                set external_id=%s where account_id=%s and external_id=%s""",
                                    ("username:%s" % name,
                                     g_user.id,
                                     "username:%s" % g_user.name))
            else:
                log.debug('Insert external_id %s: %s' % (
                        g_user.id, g_user.name))
                self.cursor.execute("""insert into account_external_ids
                               (account_id, external_id)
                               values (%s, %s)""",
                                    (g_user.id, "username:%s" % name))
            g_user.name = name
        else:
            log.debug('Rename %s by moving openid' % g_user.id)
            other_g_user = self.gerrit_users.get(other_id)
            for openid in g_user.openids:
                self.moveOpenID(g_user, other_g_user, openid)

    def removeOpenID(self, g_user, openid):
        log.info('Remove openid %s from %s' % (openid, g_user.name))
        self.cursor.execute("""delete from account_external_ids
            where account_id=%s and external_id=%s""",
                    (g_user.id, openid))

    def moveOpenID(self, src_user, dest_user, openid):
        log.info('Move openid %s from %s to %s ' % (openid, src_user.name,
                                                    dest_user.name))
        self.cursor.execute("""select email_address from account_external_ids
            where account_id=%s and external_id=%s""",
                    (src_user.id, openid))
        email = self.cursor.fetchall()[0][0]

        self.removeOpenID(src_user, openid)
        self.cursor.execute("""insert into account_external_ids
                               (account_id, email_address, external_id)
                               values (%s, %s, %s)""",
                    (dest_user.id, email, openid))

    def sync(self):
        self.fixOpenIDs()
        self.addSubGroups()
        self.syncUsers()

    def getTeams(self):
        log.info('Getting teams')
        for group in self.groups.values():
            self.getTeam(group.name)

    def getTeam(self, name):
        if name in self.teams:
            return
        log.debug('Getting team %s' % name)
        try:
            lpteam = launchpad.people[name]
        except:
            return
        team = Team(lpteam.name, lpteam.display_name)
        self.teams[team.name] = team

        sub_team_names = [sub_team.name for sub_team in lpteam.sub_teams]

        for detail in lpteam.members_details:
            if detail.status not in ["Approved", "Administrator"]:
                continue

            # detail.self_link ==
            # 'https://api.launchpad.net/1.0/~team/+member/${username}'
            login = detail.self_link.split('/')[-1]

            if login in sub_team_names:
                continue

            user = self.lp_users.get(login)
            if not user:
                user = LPUser(login)
                self.lp_users[login] = user

            user.teams.append(team)
            team.members.append(user)

        for sub_team in lpteam.sub_teams:
            self.getTeam(sub_team.name)
            team.sub_teams.append(self.teams[sub_team.name])

    def addGroupToGroup(self, child_group, parent_group):
        try:
            log.info('Adding group %s to %s' % (child_group.name,
                                                parent_group.name))
            cur.execute("""insert into account_group_includes
                           (group_id, include_id)
                           values (%s, %s)""",
                        (parent_group.id, child_group.id))
        except MySQLdb.IntegrityError:
            pass

    def addSubGroups(self):
        log.info('Add subgroups')
        for team in self.teams.values():
            group = self.groups.get(team.name)
            if not group:
                continue
            for sub_team in team.sub_teams:
                sub_group = self.groups.get(sub_team.name)
                if not sub_group:
                    sub_group = self.createGroup(sub_team)
                self.addGroupToGroup(sub_group, group)

    def createGroup(self, team):
        log.info('Create group %s' % team.name)
        self.cursor.execute(
            """insert into account_group_id (s) values (NULL)""")
        self.cursor.execute("select max(s) from account_group_id")
        group_id = cur.fetchall()[0][0]

        # Match the 40-char 'uuid' that java is producing
        group_uuid = uuid.uuid4()
        second_uuid = uuid.uuid4()
        full_uuid = "%s%s" % (group_uuid.hex, second_uuid.hex[:8])

        log.debug('Adding group %s' % team.name)
        self.cursor.execute("""insert into account_groups
                       (group_id, group_type, owner_group_id,
                        name, description, group_uuid)
                       values
                       (%s, 'INTERNAL', 1, %s, %s, %s)""",
                            (group_id, team.name, team.display_name,
                             full_uuid))
        self.cursor.execute("""insert into account_group_names
                       (group_id, name) values (%s, %s)""",
                            (group_id, team.name))
        group = Group(team.name, group_id)
        self.groups[team.name] = group
        return group

    def getGerritAccountId(self, username):
        if cur.execute("""select account_id from account_external_ids where
                          external_id in (%s)""",
                       "username:%s" % username):
            return cur.fetchall()[0][0]
        return None

    def getLPUsers(self):
        log.info('Getting LP users')
        # Get info about all of the LP team members who are not already
        # in the db
        for lp_user in self.lp_users.values():
            account_id = self.getGerritAccountId(lp_user.name)
            if not account_id:
                self.getLPUser(lp_user)

    def getLPUser(self, lp_user):
        log.debug('Getting info about %s' % lp_user.name)
        # only call this if we have no info for a user
        member = launchpad.people[lp_user.name]

        openid_consumer = consumer.Consumer(
                            dict(id=randomString(16, '0123456789abcdef')),
                            None)
        openid_request = openid_consumer.begin(
                            "https://launchpad.net/~%s" % member.name)

        openid = openid_request.endpoint.getLocalID()
        lp_user.openids.append(openid)
        self.openids[openid] = lp_user

        try:
            lp_user.email = member.preferred_email_address.email
        except ValueError:
            pass

        for key in member.sshkeys:
            lp_user.ssh_keys.append("%s %s %s" %
                                    (get_type(key.keytype),
                                     key.keytext, key.comment))

    def createGerritUser(self, lp_user, skip_openids=False):
        log.info('Add %s to Gerrit DB.' % lp_user.name)
        cur.execute("""insert into account_id (s) values (NULL)""")
        cur.execute("select max(s) from account_id")
        account_id = cur.fetchall()[0][0]

        cur.execute("""insert into accounts
                       (account_id, full_name, preferred_email)
                       values (%s, %s, %s)""",
                    (account_id, lp_user.name, lp_user.email))

        g_user = GerritUser(account_id)
        g_user.name = lp_user.name
        g_user.emails.append(lp_user.email)
        self.gerrit_users[account_id] = g_user

        # account_external_ids
        ## external_id
        if not skip_openids:
            for openid in lp_user.openids:
                if not cur.execute("""select account_id
                                  from account_external_ids
                                  where account_id = %s
                                  and external_id = %s""",
                                   (account_id, openid)):
                    cur.execute("""insert into account_external_ids
                                 (account_id, email_address, external_id)
                                 values (%s, %s, %s)""",
                                (account_id, lp_user.email, openid))

        if not cur.execute("""select account_id
                              from account_external_ids
                              where account_id = %s
                              and external_id = %s""",
                           (account_id, "username:%s" % lp_user.name)):
            cur.execute("""insert into account_external_ids
                           (account_id, external_id)
                           values (%s, %s)""",
                        (account_id, "username:%s" % lp_user.name))

        if lp_user.email:
            if not cur.execute("""select account_id
                                  from account_external_ids
                                  where account_id = %s
                                  and external_id = %s""",
                               (account_id, "mailto:%s" % lp_user.email)):
                cur.execute("""insert into account_external_ids
                               (account_id, email_address, external_id)
                               values (%s, %s, %s)""",
                            (account_id, lp_user.email,
                             "mailto:%s" % lp_user.email))

        for key in lp_user.ssh_keys:
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
        return g_user

    def addWatch(self, gerrit_user, group):
        watch_name = group.name
        if group.name.endswith("-core"):
            watch_name = group.name[:-5]
        if group.name.endswith("-drivers"):
            watch_name = group.name[:-5]
        for p in self.projects:
            if watch_name in p:
                watch_name = p
                break
        print watch_name
        if watch_name in self.projects:
            if not cur.execute("""select account_id
                                  from account_project_watches
                                  where account_id = %s
                                  and project_name = %s""",
                               (gerrit_user.id, watch_name)):
                cur.execute("""insert into account_project_watches
                               VALUES
                               ("Y", "N", "N", %s, %s, "*")""",
                            (gerrit_user.id, watch_name))

    def syncUsers(self):
        for lp_user in self.lp_users.values():
            g_id = self.getGerritAccountID(lp_user.name)
            g_user = self.gerrit_users.get(g_id)
            if not g_user:
                g_user = self.createGerritUser(lp_user)
            self.syncUser(lp_user, g_user)

    def syncUser(self, lp_user, g_user):
        log.debug('Syncing user: %s' % lp_user.name)

        # account_group_members
        # user_details['add_groups'] is a list of group names for which the
        # user is either "Approved" or "Administrator"
        groups_to_add = []
        groups_to_rm = []

        for team in lp_user.teams:
            groups_to_add.append(self.groups[team.name])

        # groups_to_add is now the full list of all groups we think the user
        # should belong to. we want to limit the users groups to this list
        for group in self.groups.values():
            if group not in groups_to_add:
                if group not in groups_to_rm:
                    groups_to_rm.append(group)

        for group in groups_to_add:
            log.info('Add %s to group %s' % (lp_user.name, group.name))
            if not cur.execute("""select account_id from account_group_members
                                  where account_id = %s and group_id = %s""",
                               (g_user.id, group.id)):
                # The current user does not exist in the group. Add it.
                cur.execute("""insert into account_group_members
                               (account_id, group_id)
                               values (%s, %s)""", (g_user.id, group.id))
                self.addWatch(g_user, group)

        for group in groups_to_rm:
            cur.execute("""delete from account_group_members
                           where account_id = %s and group_id = %s""",
                        (g_user.id, group.id))


if options.skip_prep and os.path.exists('/tmp/lpcache.pickle'):
    log.info('Loading pickle')
    out = open('/tmp/lpcache.pickle', 'rb')
    sync = pickle.load(out)
    out.close()
else:
    log.info('Initializing')
    sync = Sync()
    sync.prep()
    log.info('Saving pickle')
    out = open('/tmp/lpcache.pickle', 'wb')
    pickle.dump(sync, out, -1)
    out.close()

if not options.prep_only:
    log.info('Syncing')
    sync.sync()

if not options.skip_dump:
    os.system("ssh -i %s -p29418 %s@localhost gerrit flush-caches" %
              (GERRIT_SSH_KEY, GERRIT_USER))

conn.commit()

log.info('Gerrit user sync stop ' + str(datetime.now()))
