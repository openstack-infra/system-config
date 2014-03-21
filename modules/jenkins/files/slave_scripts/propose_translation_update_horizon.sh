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

ORG=openstack
PROJECT=horizon
COMMIT_MSG="Imported Translations from Transifex"

git config user.name "OpenStack Jenkins"
git config user.email "jenkins@openstack.org"
git config gitreview.username "jenkins"

git review -s

# See if there is an open change in the transifex/translations topic
# If so, get the change id for the existing change for use in the commit msg.
change_info=`ssh -p 29418 review.openstack.org gerrit query --current-patch-set status:open project:$ORG/$PROJECT topic:transifex/translations owner:jenkins`
previous=`echo "$change_info" | grep "^  number:" | awk '{print $2}'`
if [ "x${previous}" != "x" ] ; then
    change_id=`echo "$change_info" | grep "^change" | awk '{print $2}'`
    # read return a non zero value when it reaches EOF. Because we use a
    # heredoc here it will always reach EOF and return a nonzero value.
    # Disable -e temporarily to get around the read.
    set +e
    read -d '' COMMIT_MSG <<EOF
Imported Translations from Transifex

Change-Id: $change_id
EOF
    set -e
fi

# Initialize the transifex client, if there's no .tx directory
if [ ! -d .tx ] ; then
    tx init --host=https://www.transifex.com
fi

# Horizon JavaScript Translations
tx set --auto-local -r ${PROJECT}.${PROJECT}-js-translations \
"${PROJECT}/locale/<lang>/LC_MESSAGES/djangojs.po" --source-lang en \
--source-file ${PROJECT}/locale/en/LC_MESSAGES/djangojs.po -t PO --execute
# Horizon Translations
tx set --auto-local -r ${PROJECT}.${PROJECT}-translations \
"${PROJECT}/locale/<lang>/LC_MESSAGES/django.po" --source-lang en \
--source-file ${PROJECT}/locale/en/LC_MESSAGES/django.po -t PO --execute
# OpenStack Dashboard Translations
tx set --auto-local -r ${PROJECT}.openstack-dashboard-translations \
"openstack_dashboard/locale/<lang>/LC_MESSAGES/django.po" --source-lang en \
--source-file openstack_dashboard/locale/en/LC_MESSAGES/django.po -t PO --execute

# Pull all upstream translations
tx pull -a

# Invoke run_tests.sh to update the po files
# Or else, "../manage.py makemessages" can be used.
./run_tests.sh --makemessages -V

PO_FILES=`find horizon/locale openstack_dashboard/locale -name '*.po'`

# Add all changed files to git
git add horizon/locale/* openstack_dashboard/locale/*

# Don't send a review if the only things which have changed are the creation
# date or comments.
if [ `git diff --cached | egrep -v "(POT-Creation-Date|^[\+\-]#|^\+{3}|^\-{3})" | egrep -c "^[\-\+]"` -gt 0 ]
then
    # Commit and review
    git commit -F- <<EOF
$COMMIT_MSG
EOF
    git review -t transifex/translations

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
