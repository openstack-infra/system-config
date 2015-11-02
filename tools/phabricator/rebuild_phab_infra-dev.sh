#!/bin/bash

# This script serves two purposes:
# * Reproduces the workflow for Migrating to Maniphest.
# * Provides a quick and nasty tool to test that workflow.
#
# This script will provide the workflow for a production migration
# script (Python) that is yet to be written. It also provides a quick overview
# of what's involved.

#set -eu

# Set the configuration options:
REPOROOT="/home/ubuntu"
PHAB="/phabricator"
INSTANCES="/phabricator/instances/dev"
PHABROOT="/phabricator/instances/dev/phabricator"
MySQL="/usr/bin/mysql"
PUPPET="/usr/bin/puppet"
PHABDB_STARTS_WITH="phabricator_"
MyUSER="root"
DBS="$($MySQL -u $MyUSER -Bse 'show databases')"
SUDO="/usr/bin/sudo"
WEBDO="/usr/bin/sudo -u www-data"
GITLIBPHRU='git clone https://github.com/psigen/libphremoteuser.git'
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
MyEMAIL="craige@mcwhirter.com.au"

# Stop the phabricator daemon
$SUDO $PHABROOT/bin/phd stop

# Drop the phabricator databases:
for db in $DBS; do

if [[ "$db" == $PHABDB_STARTS_WITH* ]]; then
    echo "${BOLD}Deleting $db${NORMAL}"
    $MySQL -u $MyUSER -Bse "drop database $db"
fi

done

echo "${BOLD}Removing the root directory of Phabricator...${NORMAL}"
$SUDO /bin/rm -rf $PHAB

echo "${BOLD}Rebuilding Phabricator from Puppet...${NORMAL}"
$SUDO $PUPPET apply $REPOROOT/phabricator-tools/vagrant/puppet/phabricator/manifests/default.pp --modulepath $REPOROOT/phabricator-tools/vagrant/puppet
echo "${BOLD}Copying across the local.json file...${NORMAL}"
$SUDO cp $REPOROOT/phabricator-tools/local.json $PHABROOT/conf/local/

echo "${BOLD}Dropping and re-creating the Storyboard database...${NORMAL}"
$MySQL -u $MyUSER -Bse "drop database storyboard;"
$MySQL -u $MyUSER -Bse "create database storyboard;"
echo "${BOLD}Importing the Storyboard database from backup...${NORMAL}"
$MySQL -u $MyUSER -D storyboard < $REPOROOT/storyboard.sql

echo "${BOLD}Migrating Storyboard to Phabricator...${NORMAL}"
$MySQL -u $MyUSER < $REPOROOT/puppet-phabricator/migrate-to-phab.sql

echo "${BOLD}Setting permissions correctly...${NORMAL}"
$SUDO /bin/chown -R www-data:www-data $PHAB

echo "${BOLD}Dropping in the REMOTE_USER extension...${NORMAL}"
$WEBDO $GITLIBPHRU $INSTANCES/libphremoteuser

echo "${BOLD}Letting Phabricator know about libphremoteuser...${NORMAL}"
cd $PHABROOT
$WEBDO $PHABROOT/bin/config set load-libraries '["libphremoteuser/src"]'

echo "${BOLD}Starting the phabricator daemon...${NORMAL}"
$WEBDO $PHABROOT/bin/phd start

echo "${BOLD}Resolving issues identified by Phabricator:${NORMAL}"
echo "${BOLD}Upgrading storage...${NORMAL}"
$SUDO /etc/init.d/apache2 stop
$WEBDO $PHABROOT/bin/phd stop
$WEBDO $PHABROOT/bin/storage upgrade --force
$SUDO /etc/init.d/apache2 start
$WEBDO $PHABROOT/bin/phd start

echo "${BOLD}Making Craige an admin so he can check all the things:${NORMAL}"
PHID_USER="$($MySQL -u $MyUSER -Bse 'select userPHID from phabricator_user.user_email where address = "craige@mcwhirter.com.au"')"
echo "${BOLD}Craige's PHID is $PHID_USER.${NORMAL}"
echo "${BOLD}Making Craige an admin user:${NORMAL}"
$MySQL -u $MyUSER -Bse "update phabricator_user.user set isAdmin = 1 where phid = '$PHID_USER'"
echo "${BOLD}Obtaining a recovery URL for Craige...${NORMAL}"
$WEBDO $PHABROOT/bin/auth recover $MyEMAIL
