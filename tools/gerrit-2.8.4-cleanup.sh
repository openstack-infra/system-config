#!/bin/bash
# The purpose of this script is to cleanup a few miscellaneous projects in our
# Gerrit 2.8.4  This script should be executed on Gerrit 2.8.4 data
# (before upgrading to a newer version) and it should be run on review.o.o
# with a user that has adequate permissions to do this stuff.
#
# To execute:
#   ./gerrit-2.8.4-cleanup.sh /home/gerrit2/review_site


function get_config_data {
    # Get DB config from existing gerrit site
    local config_path=$1
    local config="$1/etc/gerrit.config"
    local secure="$1/etc/secure.config"

    [[ ! -e "${config}" ]] && \
        { echo "No gerrit config file supplied!"; exit 2; }
    [[ ! -e "${secure}" ]] && \
        { echo "No gerrit secure file supplied!"; exit 2; }

    CONFIG=${config}
    DB_HOST=$(git config --file ${config} --get database.hostname)
    DB_PORT=$(git config --file ${config} --get database.port)
    if [ -z "${DB_PORT}" ] ; then
        DB_PORT="3306"
    fi
    DB_NAME=$(git config --file ${config} --get database.database)
    DB_USER=$(git config --file ${config} --get database.username)
    DB_PASSWD=$(git config --file ${secure} --get database.password)
}


function fix_reindex {
    # Fix the following errors:
    # Reindexing changes: projects: 37% (292/786), 23%
    #     (54540/234931)(-)[2015-10-21 18:14:26,609]
    #     ERROR com.google.gerrit.server.index.Schema :
    #     error getting field tr of
    #     ChangeData{Change{253 (I62f965ca7f14f589e3b299ea46729efb68abd06f),
    #     dest=openstack/openstack-ci,refs/heads/master, status=M}}
    #     com.google.gwtorm.server.OrmException:
    #     org.eclipse.jgit.errors.RepositoryNotFoundException:
    #     repository not found:
    #     /home/ubuntu/gerrit_testsite/git/openstack/openstack-ci
    #     at com.google.gerrit.server.index.ChangeField$15.get
    #     (ChangeField.java:301)
    #
    # which is caused by a mistmatch from projects that exists in the gerrit db
    # but not in the review_site/git folder. This script will remove the
    # mismatched project from the Gerrit DB.

    echo "Removing projects from DB to fix reindex errors"
    # remove openstack/openstack-ci repo
    mysql -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} \
        ${DB_PASSWD:+-p${DB_PASSWD}} ${DB_NAME} -e \
        "DELETE FROM account_project_watches WHERE" \
        "project_name='openstack/openstack-ci';"
    mysql -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} \
        ${DB_PASSWD:+-p${DB_PASSWD}} ${DB_NAME} -e \
        "DELETE FROM changes WHERE dest_project_name='openstack/openstack-ci';"
    mysql -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} \
        ${DB_PASSWD:+-p${DB_PASSWD}} ${DB_NAME} -e \
        "DELETE FROM submodule_subscriptions WHERE" \
        "submodule_project_name='openstack/openstack-ci';"

    # remove openstack-ci/gerrit-verification-status-plugin
    mysql -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} \
        ${DB_PASSWD:+-p${DB_PASSWD}} ${DB_NAME} -e \
        "DELETE FROM account_project_watches WHERE" \
        "project_name='openstack-ci/gerrit-verification-status-plugin';"
    mysql -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} \
        ${DB_PASSWD:+-p${DB_PASSWD}} ${DB_NAME} -e \
        "DELETE FROM changes WHERE" \
        "dest_project_name='openstack-ci/gerrit-verification-status-plugin';"
    mysql -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} \
        ${DB_PASSWD:+-p${DB_PASSWD}} ${DB_NAME} -e \
        "DELETE FROM submodule_subscriptions WHERE" \
        "submodule_project_name="\
        "'openstack-ci/gerrit-verification-status-plugin';"

    # remove openstack/openstack-puppet
    mysql -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} \
        ${DB_PASSWD:+-p${DB_PASSWD}} ${DB_NAME} -e \
        "DELETE FROM account_project_watches WHERE" \
        "project_name='openstack/openstack-puppet';"
    mysql -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} \
        ${DB_PASSWD:+-p${DB_PASSWD}} ${DB_NAME} -e \
        "DELETE FROM changes WHERE" \
        "dest_project_name='openstack/openstack-puppet';"
    mysql -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} \
        ${DB_PASSWD:+-p${DB_PASSWD}} ${DB_NAME} -e \
        "DELETE FROM submodule_subscriptions WHERE" \
        "submodule_project_name='openstack/openstack-puppet';"
}

function fix_project_rename {
    # Fix a typo on a previous project rename:
    # Reference:
    #   openstack-attic/akanada -> openstack-attic/akanda
    #    (NEEDS GERRIT CHANGE, MANUAL CLEANUP)
    #  the patch was fine but the gerrit db commands had an error in the
    #  name in steps 5, 6 and 8:
    #  https://etherpad.openstack.org/p/project-renames-November-6-2015

    echo "Fixing project rename typos"
    # 5. Update the database on review.openstack.org
    mysql -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} \
        ${DB_PASSWD:+-p${DB_PASSWD}} ${DB_NAME} -e \
        "update account_project_watches" \
        "set project_name='openstack-attic/akanda'" \
        "where project_name='openstack-attic/akanada';"
    mysql -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} \
        ${DB_PASSWD:+-p${DB_PASSWD}} ${DB_NAME} -e \
        "update changes set dest_project_name='openstack-attic/akanda'," \
        "created_on=created_on where dest_project_name="\
        "'openstack-attic/akanada';"

    # 6. Move both the Git repository and the mirror on review.openstack.org
    sudo mv ${REVIEW_SITE_PATH}/git/\
        {openstack-attic/akanada,openstack-attic/akanda}.git
    sudo mv /opt/lib/git/\
        {openstack-attic/akanada,openstack-attic/akanda}.git

    # 8. Move the Git repository on git{01-08}.openstack.org
    #    (while the Lucene reindex is running):
    # This command should be run on the git servers (gitXX.openstack.org)
    echo "# Run this command on the git servers (gitXX.openstack.org)"
    echo "sudo mv /var/lib/git/"\
        "{openstack-attic/akanada,openstack-attic/akanda}.git"
}

# main
REVIEW_SITE_PATH=$1
get_config_data ${REVIEW_SITE_PATH}
fix_reindex
fix_project_rename
