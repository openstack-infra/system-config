#!/usr/bin/env python
#echo "${BOLD}Copying across the local.json file...${NORMAL}"
#$SUDO cp $REPOROOT/phabricator-tools/local.json $PHABROOT/conf/local/
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
WEBDO="/usr/bin/sudo -u www-data"
GITLIBPHRU='git clone https://github.com/psigen/libphremoteuser.git'
#BOLD=$(tput bold)
#NORMAL=$(tput sgr0)
MyEMAIL="craige@mcwhirter.com.au"

def stopphab():
    ''' Stop the phabricator daemon: '''
    phd = "%s/bin/phd" % PHABROOT
    if os.path.exists(phd):
        print "Stopping phd"
        subprocess.call([SUDO, phd, "stop"])
    else:
        print ("%s was not present on this instance." % phd)

def startphab():
    ''' Start the phabricator daemon: '''
    phd = "%s/bin/phd" % PHABROOT
    print phd
    subprocess.call([SUDO, phd, "start"])

def dropphab():
    ''' Drop the phabricator databases: '''
    #db = pymysql.connect(host='localhost', user='root', passwd='')
    #cursor = db.cursor()
    sql = "SHOW DATABASES"
    #cursor.execute(sql)
    CURSOR.execute(sql)
    dbs = CURSOR.fetchall()
    for db in dbs:
        dbi = str(db).strip('(\',)')
        if dbi.startswith(PHABDB_STARTS_WITH):
            sql = ("DROP DATABASE %s" % dbi)
            CURSOR.execute(sql)
            print "Deleted %s" % dbi

def deletephab():
    '''Removing the root directory of Phabricator'''
    #$SUDO /bin/rm -rf $PHAB
    if os.path.exists(PHAB):
        subprocess.call([SUDO, "/bin/rm", "-rf", PHAB])
        if os.path.exists(PHAB):
            print ("Failed to delete %s. Exiting" % PHAB)
            exit()
        else:
            print ("Deleted %s" % PHAB)
    else:
        print ("%s had already been deleted." % PHAB)

def rebuildphab():
    '''Rebuild Phabricator from Puppet.'''
    #$SUDO $PUPPET apply $REPOROOT/phabricator-tools/vagrant/puppet/phabricator/manifests/default.pp --modulepath $REPOROOT/phabricator-tools/vagrant/puppet
    if os.path.exists('%s/phabricator-tools' % HOME):
        subprocess.call([SUDO, PUPPET, "apply", ("%s/phabricator-tools/vagrant/puppet/phabricator/manifests/default.pp" % HOME), "--modulepath", ("%s/phabricator-tools/vagrant/puppet" % HOME)])

def configurephab():
    '''Configure Phabricator for our uses'''
    # Copy our currnet local.json file into place:
    subprocess.call([SUDO, "cp", ("%s/phabricator-tools/local.json" % HOME), ("%s/conf/local/" % PHABROOT)])
    print ("Copied across local.conf")

def rebuildstoryboard():
    '''Drop and re-create the Storyboard database'''
    sql = "DROP DATABASE storyboard"
    CURSOR.execute(sql)
    print (cursor.fetchall())
    sql = "CREATE DATABASE storyboard"
    CURSOR.execute(sql)
    print (cursor.fetchall())

stopphab()
dropphab()
deletephab()
rebuildphab()
configurephab()
rebuildstoryboard()


#echo "${BOLD}Importing the Storyboard database from backup...${NORMAL}"
#$MySQL -u $MyUSER -D storyboard < $REPOROOT/storyboard.sql

#echo "${BOLD}Migrating Storyboard to Phabricator...${NORMAL}"
#$MySQL -u $MyUSER < $REPOROOT/puppet-phabricator/migrate-to-phab.sql
#
#echo "${BOLD}Setting permissions correctly...${NORMAL}"
#$SUDO /bin/chown -R www-data:www-data $PHAB
#
#echo "${BOLD}Dropping in the REMOTE_USER extension...${NORMAL}"
#$WEBDO $GITLIBPHRU $INSTANCES/libphremoteuser
#
#echo "${BOLD}Letting Phabricator know about libphremoteuser...${NORMAL}"
#cd $PHABROOT
#$WEBDO $PHABROOT/bin/config set load-libraries '["libphremoteuser/src"]'
#
#echo "${BOLD}Starting the phabricator daemon...${NORMAL}"
#$WEBDO $PHABROOT/bin/phd start
#
#echo "${BOLD}Resolving issues identified by Phabricator:${NORMAL}"
#echo "${BOLD}Upgrading storage...${NORMAL}"
#$SUDO /etc/init.d/apache2 stop
#$WEBDO $PHABROOT/bin/phd stop
#$WEBDO $PHABROOT/bin/storage upgrade --force
#$SUDO /etc/init.d/apache2 start
#$WEBDO $PHABROOT/bin/phd start
#
#echo "${BOLD}Making Craige an admin so he can check all the things:${NORMAL}"
#PHID_USER="$($MySQL -u $MyUSER -Bse 'select userPHID from phabricator_user.user_email where address = "craige@mcwhirter.com.au"')"
#echo "${BOLD}Craige's PHID is $PHID_USER.${NORMAL}"
#echo "${BOLD}Making Craige an admin user:${NORMAL}"
#$MySQL -u $MyUSER -Bse "update phabricator_user.user set isAdmin = 1 where phid = '$PHID_USER'"
#echo "${BOLD}Obtaining a recovery URL for Craige...${NORMAL}"
#WEBDO $PHABROOT/bin/auth recover $MyEMAIL
