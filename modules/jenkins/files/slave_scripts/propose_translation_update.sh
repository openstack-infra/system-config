#!/bin/bash -xe

PROJECT=$1

git config user.name "OpenStack Jenkins"
git config user.email "jenkins@openstack.org"

# See if there is an open change in the transifex/translations topic
# If so, amend the commit with new changes since then
previous=`ssh -p 29418 review.openstack.org gerrit query --current-patch-set status:open project:openstack/$PROJECT topic:transifex/translations | grep "^  number:" | awk '{print $2}'`
if [ "x${previous}" != "x" ] ; then
    git review -d ${previous}
    amend="--amend"
fi

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
    # Commit and review
    git commit ${amend} -m "Imported Translations from Transifex"
    git review -t transifex/translations

    # Push changes to transifex
    tx --debug --traceback push -st
fi
