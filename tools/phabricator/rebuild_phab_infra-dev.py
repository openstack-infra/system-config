#!/usr/bin/env python
# Copyright (c) 2015 Hewlett-Packard Development Company, L.P.
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
# See the License for the specific language governing permissions and
# limitations under the License.

# This script serves two purposes:
# * Reproduces the workflow for Migrating to Maniphest.
# * Provides a quick and nasty tool to test that workflow.
#
# Some of the contents of this script will need to be stripped out and added to
# ansible and puppet prior to migration.

import os
from git import remote
import pymysql
import subprocess
import time

# Set the configuration options:
HOME = os.getenv('HOME')
PHAB = '/phabricator'
INSTANCES = ("%s/instances/dev" % PHAB)
PHABROOT = ("%s/phabricator" % INSTANCES)
MySQL = pymysql.connect(host='localhost', user='root', passwd='')
PUPPET= "/usr/bin/puppet"
PHABDB_STARTS_WITH = "phabricator_"
MyUSER = "root"
CURSOR = MySQL.cursor()
SUDO = "/usr/bin/sudo"
WEBDO = '/usr/bin/sudo -u www-data'
GITLIBPHRU = 'git clone https://github.com/psigen/libphremoteuser.git'
MyEMAIL = 'craige@mcwhirter.com.au'



def BOLD(msg):
    '''Define some bold text.'''
    return u'\033[1m%s\033[0m' % msg


def stopphab():
    ''' Stop the phabricator daemon: '''
    phd = "%s/bin/phd" % PHABROOT
    if os.path.exists(phd):
        print "Stopping phd"
        os.system('%s %s stop' % (WEBDO, phd))
    else:
        print (color.BOLD + ("%s was not present on this instance." % phd) + color.END)

def startphab():
    ''' Start the phabricator daemon: '''
    phd = "%s/bin/phd" % PHABROOT
    if os.path.exists(phd):
        print "Starting phd"
        os.system('%s %s start' % (WEBDO, phd))
    else:
        print BOLD("%s was not present on this instance." % phd)

def dropphab():
    ''' Drop the phabricator databases: '''
    sql = "SHOW DATABASES"
    CURSOR.execute(sql)
    dbs = CURSOR.fetchall()
    for db in dbs:
        dbi = str(db).strip('(\',)')
        if dbi.startswith(PHABDB_STARTS_WITH):
            sql = ("DROP DATABASE %s" % dbi)
            CURSOR.execute(sql)
            print BOLD("Deleted %s" % dbi)
    MySQL.commit()

def deletephab():
    ''' Removing the root directory of Phabricator '''
    if os.path.exists(PHAB):
        subprocess.call([SUDO, "/bin/rm", "-rf", PHAB])
        if os.path.exists(PHAB):
            print BOLD("Failed to delete %s. Exiting" % PHAB)
            exit()
        else:
            print BOLD("Deleted %s" % PHAB)
    else:
        print BOLD("%s had already been deleted." % PHAB)

def rebuildphab():
    ''' Rebuild Phabricator from Puppet. '''
    if os.path.exists('%s/phabricator-tools' % HOME):
        subprocess.call([SUDO, PUPPET, "apply", ("%s/phabricator-tools/vagrant/puppet/phabricator/manifests/default.pp" % HOME), "--modulepath", ("%s/phabricator-tools/vagrant/puppet" % HOME)])

def remoteuser():
    ''' Dropping in the REMOTE_USER extension... '''
    os.system('%s %s %s/libphremoteuser' % (SUDO, GITLIBPHRU, INSTANCES))

def configurephab():
    ''' Configure Phabricator for our uses '''

    print BOLD('Copy our current local.json file into place:')
    subprocess.call([SUDO, "cp", ("%s/phabricator-tools/local.json" % HOME), ("%s/conf/local/" % PHABROOT)])

    print BOLD('Setting file permissions correctly')
    subprocess.call([SUDO, '/bin/chown', '-R', 'www-data:www-data', PHAB])

    print BOLD('Letting Phabricator know about libphremoteuser...')
    os.system('sudo -u www-data /phabricator/instances/dev/phabricator/bin/config set load-libraries \'["libphremoteuser/src"]\'')

    print BOLD('Enabling RemoteUser...')

    print BOLD('Resolving issues identified by Phabricator:')
    print BOLD('Upgrading storage...')
    os.system('%s /etc/init.d/apache2 stop' % SUDO)
    os.system('%s %s/bin/storage upgrade --force' % (WEBDO, PHABROOT))
    os.system('%s /etc/init.d/apache2 start' % SUDO)

def dropcreatestoryboard():
    sql = "DROP DATABASE storyboard"
    CURSOR.execute(sql)
    sql = "CREATE DATABASE storyboard"
    CURSOR.execute(sql)

def rebuildstoryboard():
    ''' Drop and re-create the Storyboard database '''
    sql = "SHOW DATABASES"
    CURSOR.execute(sql)
    dbs = str(CURSOR.fetchall()).strip('(\',)')
    if 'storyboard' in dbs:
        print BOLD('storyboard database exists, dropping and creating')
        dropcreatestoryboard()
    else:
        print BOLD('storyboard database does not exist, creating')
        sql = "CREATE DATABASE storyboard"
        CURSOR.execute(sql)
    print BOLD('Importing the Storyboard database from backup...')
    sbsql = open('/home/ubuntu/storyboard.sql', 'r')
    CURSOR.execute('USE storyboard')
    CURSOR.execute(file.read(sbsql))

def dbmigration():
    ''' Migrate Storyboard to Phab '''
    print BOLD('Migrating Storyboard to Phabricator...')
    os.system('/usr/bin/mysql -u root < /home/ubuntu/system-config/tools/phabricator/migrate-to-phab.sql')

def admincraige():
    ''' Make Craige an admin so he can check all the things. '''
    #phid_user = "$($MySQL -u $MyUSER -Bse 'select userPHID from phabricator_user.user_email where address = "craige@mcwhirter.com.au"')"
    sql = 'SELECT userPHID FROM phabricator_user.user_email WHERE address = \'%s\'' % MyEMAIL
    print(sql)
    CURSOR.execute(sql)
    phid_user = str(CURSOR.fetchall()).strip('(\',)')
    print BOLD("Craige's PHID is %s." % phid_user)
    sql = 'SELECT isAdmin FROM phabricator_user.user WHERE phid = \'%s\'' % phid_user
    CURSOR.execute(sql)
    isadmin = str(CURSOR.fetchall()).strip('(\',)')
    print BOLD('isadmin is: %s' % isadmin)
    if isadmin == '1':
        print BOLD('Craige is already an admin user.')
    else:
        print BOLD('Making Craige an admin user')
        sql = ('UPDATE phabricator_user.user SET isAdmin = 1 WHERE phid = \'%s\'' % phid_user)
        print(sql)
        CURSOR.execute(sql)
        out = str(CURSOR.fetchall()).strip('(\',)')
        MySQL.commit()
        print BOLD('what came out was: %s' % out)

    sql = 'SELECT isAdmin FROM phabricator_user.user WHERE phid = \'%s\'' % phid_user
    CURSOR.execute(sql)
    isadmin = str(CURSOR.fetchall()).strip('(\',)')
    print BOLD('isadmin is: %s' % isadmin)
    print BOLD('Obtaining a recovery URL for Craige...')
    os.system('%s %s/bin/auth recover %s' % (WEBDO, PHABROOT, MyEMAIL))

stopphab()
dropphab()
deletephab()
rebuildphab()
remoteuser()
configurephab()
rebuildstoryboard()
print('Sleeping to allow rebuildstoryboard() to complete....')
time.sleep(10)
dbmigration()
startphab()
admincraige()
