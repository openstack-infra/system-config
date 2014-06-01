#!/bin/bash -xe
# Common code used by propose_translation_update.sh and
# upstream_translation_update.sh

# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

# Initial transifex setup
function setup_translation ()
{

    # Initialize the transifex client, if there's no .tx directory
    if [ ! -d .tx ] ; then
        tx init --host=https://www.transifex.com
    fi
}

# Setup a project for transifex
function setup_project ()
{
    local project=$1

    tx set --auto-local -r ${project}.${project}-translations \
        "${project}/locale/<lang>/LC_MESSAGES/${project}.po" \
        --source-lang en \
        --source-file ${project}/locale/${project}.pot -t PO \
        --execute
}

# Setup project horizon for transifex
function setup_horizon ()
{
    local project=horizon

    # Horizon JavaScript Translations
    tx set --auto-local -r ${project}.${project}-js-translations \
        "${project}/locale/<lang>/LC_MESSAGES/djangojs.po" \
        --source-lang en \
        --source-file ${project}/locale/en/LC_MESSAGES/djangojs.po \
        -t PO --execute

    # Horizon Translations
    tx set --auto-local -r ${project}.${project}-translations \
        "${project}/locale/<lang>/LC_MESSAGES/django.po" \
        --source-lang en \
        --source-file ${project}/locale/en/LC_MESSAGES/django.po \
        -t PO --execute

    # OpenStack Dashboard Translations
    tx set --auto-local -r ${project}.openstack-dashboard-translations \
        "openstack_dashboard/locale/<lang>/LC_MESSAGES/django.po" \
        --source-lang en \
        --source-file openstack_dashboard/locale/en/LC_MESSAGES/django.po \
        -t PO --execute
}

# Set global variable DocFolder for manuals projects
function init_manuals ()
{
    project=$1

    DocFolder="doc"
    if [ $project = "api-site" ] ; then
        DocFolder="./"
    fi
}

# Setup project manuals projects (api-site, openstack-manuals,
# operations-guide) for transifex
function setup_manuals ()
{
    # Generate pot one by one
    for FILE in ${DocFolder}/*
    do
        # Skip non-directories
        if [ ! -d $FILE ]
        then
            continue
        fi
        DOCNAME=${FILE#${DocFolder}/}
        # Ignore directories that will not get translated
        if [ "$DOCNAME" == "www" -o "$DOCNAME" == "tools" -o "$DOCNAME" == "generated" -o "$DOCNAME" == "publish-docs" ]
        then
            continue
        fi
        # Update the .pot file
        ./tools/generatepot ${DOCNAME}
        if [ -f ${DocFolder}/${DOCNAME}/locale/${DOCNAME}.pot ]
        then
            # Add all changed files to git
            git add ${DocFolder}/${DOCNAME}/locale/*
            # Set auto-local
            tx set --auto-local -r openstack-manuals-i18n.${DOCNAME} \
                "${DocFolder}/${DOCNAME}/locale/<lang>.po" --source-lang en \
                --source-file ${DocFolder}/${DOCNAME}/locale/${DOCNAME}.pot \
                -t PO --execute
        fi
    done

}

# Setup git so that git review works
function setup_git ()
{
    git config user.name "OpenStack Proposal Bot"
    git config user.email "openstack-infra@lists.openstack.org"
    git config gitreview.username "proposal-bot"
}

# Setup project so that git review works, sets global variable
# COMMIT_MSG.
function setup_review ()
{
    local ORG="$1"
    local PROJECT="$2"

    COMMIT_MSG="Imported Translations from Transifex"

    git review -s

    # See if there is an open change in the transifex/translations
    # topic. If so, get the change id for the existing change for use
    # in the commit msg.
    change_info=`ssh -p 29418 proposal-bot@review.openstack.org gerrit query --current-patch-set status:open project:$ORG/$PROJECT topic:transifex/translations owner:proposal-bot`
    previous=`echo "$change_info" | grep "^  number:" | awk '{print $2}'`
    if [ "x${previous}" != "x" ] ; then
        change_id=`echo "$change_info" | grep "^change" | awk '{print $2}'`
        # Read returns a non zero value when it reaches EOF. Because we use a
        # heredoc here it will always reach EOF and return a nonzero value.
        # Disable -e temporarily to get around the read.
        set +e
        read -d '' COMMIT_MSG <<EOF
Imported Translations from Transifex

Change-Id: $change_id
EOF
        set -e
    fi
}

# Propose patch using COMMIT_MSG
function send_patch ()
{
    # Don't send a review if nothing has changed.
    if [ `git diff --cached |wc -l` -gt 0 ]
    then
        # Commit and review
        git commit -F- <<EOF
$COMMIT_MSG
EOF
        git review -t transifex/translations

    fi
}

# Setup global variables LEVELS and LKEYWORDS
function setup_loglevel_vars ()
{
    # Strings for various log levels
    LEVELS="info warning error critical"
    # Keywords for each log level:
    declare -g -A LKEYWORD
    LKEYWORD['info']='_LI'
    LKEYWORD['warning']='_LW'
    LKEYWORD['error']='_LE'
    LKEYWORD['critical']='_LC'
}

# Setup transifex configuration for log level message translation.
# Needs variables setup via setup_loglevel_vars.
function setup_loglevel_project ()
{
    project=$1

    for level in $LEVELS ; do
        # Bootstrapping: Create file if it does not exist yet,
        # otherwise "tx set" will fail.
        if [ ! -e  ${project}/locale/${project}-log-${level}.pot ]
        then
            touch ${project}/locale/${project}-log-${level}.pot
        fi
        tx set --auto-local -r ${project}.${project}-log-${level}-translations \
            "${project}/locale/<lang>/LC_MESSAGES/${project}-log-${level}.po" \
            --source-lang en \
            --source-file ${project}/locale/${project}-log-${level}.pot -t PO \
            --execute
    done
}

# Run extract_messages for user visible messages and log messages.
# Needs variables setup via setup_loglevel_vars.
function extract_messages_log ()
{
    project=$1

    # Update the .pot files
    python setup.py extract_messages
    for level in $LEVELS ; do
        python setup.py extract_messages --no-default-keywords \
            --keyword ${LKEYWORD[$level]} \
            --output-file ${project}/locale/${project}-log-${level}.pot
    done
}
