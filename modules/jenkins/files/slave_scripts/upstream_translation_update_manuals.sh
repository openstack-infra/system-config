#!/bin/bash -xe

DOCNAME=$1

if [ ! `echo $ZUUL_REFNAME | grep master` ]
then
    exit 0
fi

git config user.name "OpenStack Jenkins"
git config user.email "jenkins@openstack.org"

# initialize transifex client
tx init --host=https://www.transifex.com
tx set --auto-local -r openstack-manuals-i18n.${DOCNAME} "doc/src/docbkx/${DOCNAME}/locale/<lang>.po" --source-lang en --source-file doc/src/docbkx/${DOCNAME}/locale/${DOCNAME}.pot -t PO --execute

# Update the .pot file
./tools/generatepot ${DOCNAME}

# Add all changed files to git
git add doc/src/docbkx/${DOCNAME}/locale/*

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



