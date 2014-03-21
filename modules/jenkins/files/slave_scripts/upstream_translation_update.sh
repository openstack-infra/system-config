#!/bin/bash -xe

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

PROJECT=$1

# The setup for django_openstack_auth is different. The locale files
# are under openstack_auth and the transifex resource is part of
# horizon with a non-standard name. Therefore we have to special case
# it.
RESOURCE=${PROJECT}-translations
PROJECT_DIR=${PROJECT}
PO_FILE=${PROJECT}

if [ $PROJECT = "django_openstack_auth" ] ; then
    PROJECT=horizon
    PROJECT_DIR=openstack_auth
    RESOURCE=djangopo
    PO_FILE=django
fi

if [ ! `echo $ZUUL_REFNAME | grep master` ]
then
    exit 0
fi

git config user.name "OpenStack Jenkins"
git config user.email "jenkins@openstack.org"

# Initialize the transifex client, if there's no .tx directory
if [ ! -d .tx ] ; then
    tx init --host=https://www.transifex.com
fi
tx set --auto-local -r ${PROJECT}.${RESOURCE} "${PROJECT_DIR}/locale/<lang>/LC_MESSAGES/${PO_FILE}.po" --source-lang en --source-file ${PROJECT_DIR}/locale/${PROJECT_DIR}.pot -t PO --execute

# Update the .pot file
python setup.py extract_messages
PO_FILES=`find ${PROJECT_DIR}/locale -name '*.po'`
if [ -n "$PO_FILES" ]
then
    # Use updated .pot file to update translations
    python setup.py update_catalog --no-fuzzy-matching --ignore-obsolete=true
fi
# Add all changed files to git
git add $PROJECT_DIR/locale/*

if [ ! `git diff-index --quiet HEAD --` ]
then
    # Push .pot changes to transifex
    tx --debug --traceback push -s
fi
