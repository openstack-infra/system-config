#!/bin/bash
# Gerrit does not have a feature to delete Groups. This is a
# helper script to delete Gerrit groups from the database.
#
# Reference:
#     Directions for db manipulation documented in this gerrit issue:
#     https://code.google.com/p/gerrit/issues/detail?id=44
#
# To execute:
#   ./gerrit-delete-group.sh /home/gerrit2/review_site "group to remove"


function get_config_data {
    # Get DB config from existing gerrit site
    local config_path=$1
    local config="$1/etc/gerrit.config"
    local secure="$1/etc/secure.config"

    [[ ! -e "${config}" ]] && { echo "No gerrit config file supplied!"; exit 2; }
    [[ ! -e "${secure}" ]] && { echo "No gerrit secure file supplied!"; exit 2; }

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

function delete_group {
    local name="$1"

    mysql -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} ${DB_PASSWD:+-p${DB_PASSWD}} ${DB_NAME} -e "DELETE FROM account_groups WHERE name="'${name}'";"
    mysql -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} ${DB_PASSWD:+-p${DB_PASSWD}} ${DB_NAME} -e "DELETE FROM account_group_names WHERE group_id NOT IN (SELECT group_id FROM account_groups);"

}

function cleanup {
    # clean up the database a bit to remove the now orphaned records:

    mysql -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} ${DB_PASSWD:+-p${DB_PASSWD}} ${DB_NAME} -e "DELETE FROM account_group_members WHERE group_id NOT IN (SELECT group_id FROM account_groups);"
    mysql -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} ${DB_PASSWD:+-p${DB_PASSWD}} ${DB_NAME} -e "DELETE FROM account_group_members_audit WHERE group_id NOT IN (SELECT group_id FROM account_groups);"

    # % or project_rights
    mysql -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} ${DB_PASSWD:+-p${DB_PASSWD}} ${DB_NAME} -e "DELETE FROM ref_rights WHERE group_id NOT IN (SELECT group_id FROM account_groups);"
	
}

# main
REVIEW_SITE_PATH=$1
GROUP=$2
get_config_data ${REVIEW_SITE_PATH}
delete_group "${GROUP}"
cleanup
