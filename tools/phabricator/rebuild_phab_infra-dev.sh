#!/bin/bash

# This script serves two purposes:
# * Reproduces the workflow for Migrating to Maniphest.
# * Provides a quick and nasty tool to test that workflow.
#
# This script will provide the workflow for a production migration
# script (Python) that is yet to be written. It also provides a quick overview
# of what's involved.

# Set the configuration options:
REPOROOT="/home/ubuntu"
PHAB="/phabricator"
INSTANCES="/phabricator/instances/dev"
PHABROOT="/phabricator/instances/dev/phabricator"
MySQL="/usr/bin/mysql"
PUPPET="/usr/bin/puppet"
PHABDB_STARTS_WITH="phabricator_"
MyUSER="root"
DBS='$($MYSQL -u $MUSER -Bse "show databases")'
SUDO="/usr/bin/sudo"
WEBDO="/usr/bin/sudo -u www-data"
GITLIBPHRU='git clone https://github.com/psigen/libphremoteuser.git'

# Stop the phabricator daemon
$SUDO $PHABROOT/bin/phd stop

# Drop the phabricator databases:
for db in $DBS; do

if [[ "$db" == $PHABDB_STARTS_WITH* ]]; then
    echo "Deleting $db"
    $MySQL -u $MyUSER -Bse "drop database $db"
fi

done

# Remove the root directory too
$SUDO /bin/rm -rf $PHAB

# Rebuild Phabricator
$SUDO $PUPPET apply $REPOROOT/phabricator-tools/vagrant/puppet/phabricator/manifests/default.pp --modulepath $REPOROOT/phabricator-tools/vagrant/puppet
$SUDO cp $REPOROOT/phabricator-tools/local.json $PHABROOT/conf/local/

# Drop in the REMOTE_USER extension:
$WEBDO $GITLIBPHRU $INSTANCES/libphremoteuser

# Let Phabricator know about libphremoteuer
cd $PHABROOT
$WEBDO ./bin/config set load-libraries '["libphremoteuser/src"]'

# Rebuild Storybaord
$MySQL -u root -Bse "drop database storyboard; create database storyboard;"
$MySQL -u root -D storyboard < $REPOROOT/storyboard.sql

# Migrate Storyboard to Phabricator:
$MySQL -u root < $REPOROOT/puppet-phabricator/migrate-to-phab.sql

# Start the phabricator daemon
$SUDO /bin/chown -R www-data:www-data $PHAB
$WEBDO $PHABROOT/bin/phd start

# Resolving issues identified by Phabricator:
# Upgrade storage
$SUDO /etc/init.d/apache2 stop
$WEBDO $PHABROOT/bin/phd stop
$WEBDO $PHABROOT/bin/storage upgrade
$SUDO /etc/init.d/apache2 start
$WEBDO $PHABROOT/bin/phd start

