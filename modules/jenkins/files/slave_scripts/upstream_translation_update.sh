#!/bin/bash -xe

PROJECT=$1

if [ ! `echo $ZUUL_REFNAME | grep master` ]
then
    exit 0
fi

git config user.name "OpenStack Jenkins"
git config user.email "jenkins@openstack.org"

# initialize transifex client
tx init --host=https://www.transifex.com
tx set --auto-local -r ${PROJECT}.${PROJECT}-translations "${PROJECT}/locale/<lang>/LC_MESSAGES/${PROJECT}.po" --source-lang en --source-file ${PROJECT}/locale/${PROJECT}.pot --execute

# Pull all upstream translations
tx pull -a
# Update the .pot file
python setup.py extract_messages
# Use updated .pot file to update translations
python setup.py update_catalog
# Add all changed files to git
git add $PROJECT/locale/*

if [ ! `git diff-index --quiet HEAD --` ]
then
    # Push .pot changes to transifex
    tx --debug --traceback push -s
    # Push translation changes to transifex
    # Disable -e as we can live with failed translation pushes (failures
    # occur when a translation file has no translations in it not really
    # error worthy but they occur)
    set +e
    tx --debug --traceback push -t --skip
    set -e
fi
