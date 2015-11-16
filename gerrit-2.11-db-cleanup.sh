#!/bin/bash

# The purpose of this script is to remove the following errors:
# Reindexing changes: projects: 37% (292/786), 23% (54540/234931) (-)[2015-10-21 18:14:26,609]
#           ERROR com.google.gerrit.server.index.Schema : error getting field tr of
#           ChangeData{Change{253 (I62f965ca7f14f589e3b299ea46729efb68abd06f),
#           dest=openstack/openstack-ci,refs/heads/master, status=M}}
#           com.google.gwtorm.server.OrmException: org.eclipse.jgit.errors.RepositoryNotFoundException:
#           repository not found: /home/ubuntu/gerrit_testsite/git/openstack/openstack-ci
#           at com.google.gerrit.server.index.ChangeField$15.get(ChangeField.java:301)
#
# which is caused by a mistmatch from projects that exists in the gerrit db but not in the review_site/git folder.
# This script will remove the mismatched project from the Gerrit DB. 

# remove openstack/openstack-ci repo
mysql -uroot -ppassword reviewdb -e "DELETE FROM account_project_watches WHERE project_name='openstack/openstack-ci';"
mysql -uroot -ppassword reviewdb -e "DELETE FROM changes WHERE dest_project_name='openstack/openstack-ci';"
mysql -uroot -ppassword reviewdb -e "DELETE FROM submodule_subscriptions WHERE submodule_project_name='openstack/openstack-ci';"

# remove openstack-ci/gerrit-verification-status-plugin
mysql -uroot -ppassword reviewdb -e "DELETE FROM account_project_watches WHERE project_name='openstack-ci/gerrit-verification-status-plugin';"
mysql -uroot -ppassword reviewdb -e "DELETE FROM changes WHERE dest_project_name='openstack-ci/gerrit-verification-status-plugin';"
mysql -uroot -ppassword reviewdb -e "DELETE FROM submodule_subscriptions WHERE submodule_project_name='openstack-ci/gerrit-verification-status-plugin';"

# remove openstack/openstack-puppet
mysql -uroot -ppassword reviewdb -e "DELETE FROM account_project_watches WHERE project_name='openstack/openstack-puppet';"
mysql -uroot -ppassword reviewdb -e "DELETE FROM changes WHERE dest_project_name='openstack/openstack-puppet';"
mysql -uroot -ppassword reviewdb -e "DELETE FROM submodule_subscriptions WHERE submodule_project_name='openstack/openstack-puppet';"
