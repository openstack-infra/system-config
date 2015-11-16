#!/bin/bash
# The purpose of this script is to cleanup a few miscellaneous projects in our
# Gerrit 2.8.4  This script should be executed on Gerrit 2.8.4 data
# (before upgrading to a newer version) and it should be run on review.o.o
# with a user that has adequate permissions to do this stuff.
#
# To execute:
#   ./gerrit-2.8.4-cleanup.sh $GERRIT_DB_USER $GERRIT_DB_PASSWORD

DB_USER=$1
DB_PASS=$2

# Fix the following errors:
# Reindexing changes: projects: 37% (292/786), 23% (54540/234931)(-)[2015-10-21 18:14:26,609]
#     ERROR com.google.gerrit.server.index.Schema : error getting field tr of
#     ChangeData{Change{253 (I62f965ca7f14f589e3b299ea46729efb68abd06f),
#     dest=openstack/openstack-ci,refs/heads/master, status=M}}
#     com.google.gwtorm.server.OrmException: org.eclipse.jgit.errors.RepositoryNotFoundException:
#     repository not found: /home/ubuntu/gerrit_testsite/git/openstack/openstack-ci
#     at com.google.gerrit.server.index.ChangeField$15.get(ChangeField.java:301)
#
# which is caused by a mistmatch from projects that exists in the gerrit db
# but not in the review_site/git folder. This script will remove the mismatched
# project from the Gerrit DB.

# remove openstack/openstack-ci repo
mysql -u$DB_USER -p$DB_PASS reviewdb -e "DELETE FROM account_project_watches WHERE project_name='openstack/openstack-ci';"
mysql -u$DB_USER -p$DB_PASS reviewdb -e "DELETE FROM changes WHERE dest_project_name='openstack/openstack-ci';"
mysql -u$DB_USER -p$DB_PASS reviewdb -e "DELETE FROM submodule_subscriptions WHERE submodule_project_name='openstack/openstack-ci';"

# remove openstack-ci/gerrit-verification-status-plugin
mysql -u$DB_USER -p$DB_PASS reviewdb -e "DELETE FROM account_project_watches WHERE project_name='openstack-ci/gerrit-verification-status-plugin';"
mysql -u$DB_USER -p$DB_PASS reviewdb -e "DELETE FROM changes WHERE dest_project_name='openstack-ci/gerrit-verification-status-plugin';"
mysql -u$DB_USER -p$DB_PASS reviewdb -e "DELETE FROM submodule_subscriptions WHERE submodule_project_name='openstack-ci/gerrit-verification-status-plugin';"

# remove openstack/openstack-puppet
mysql -u$DB_USER -p$DB_PASS reviewdb -e "DELETE FROM account_project_watches WHERE project_name='openstack/openstack-puppet';"
mysql -u$DB_USER -p$DB_PASS reviewdb -e "DELETE FROM changes WHERE dest_project_name='openstack/openstack-puppet';"
mysql -u$DB_USER -p$DB_PASS reviewdb -e "DELETE FROM submodule_subscriptions WHERE submodule_project_name='openstack/openstack-puppet';"


# Fix a typo on a previous project rename:
# Reference:
#   openstack-attic/akanada -> openstack-attic/akanda
#    (NEEDS GERRIT CHANGE, MANUAL CLEANUP)
#  the patch was fine but the gerrit db commands had an error in the
#  name in steps 5, 6 and 8:
#  https://etherpad.openstack.org/p/project-renames-November-6-2015

# 5. Update the database on review.openstack.org
mysql -u$DB_USER -p$DB_PASS reviewdb -e "update account_project_watches set project_name='openstack-attic/akanda' where project_name='openstack-attic/akanada';"
mysql -u$DB_USER -p$DB_PASS reviewdb -e "update changes set dest_project_name='openstack-attic/akanda', created_on=created_on where dest_project_name='openstack-attic/akanada';"

# 6. Move both the Git repository and the mirror on review.openstack.org
sudo mv ~gerrit2/review_site/git/{openstack-attic/akanada,openstack-attic/akanda}.git
sudo mv /opt/lib/git/{openstack-attic/akanada,openstack-attic/akanda}.git

# 8. Move the Git repository on git{01-08}.openstack.org (while the Lucene reindex is running):
# This command should be run on the git servers (gitXX.openstack.org)
echo '# Run this command on the git servers (gitXX.openstack.org)'
echo 'sudo mv /var/lib/git/{openstack-attic/akanada,openstack-attic/akanda}.git'
