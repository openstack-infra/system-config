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

ORG=$1
PROJECT=$2

# The setup for django_openstack_auth is different. The locale files
# are under openstack_auth and the transifex resource is part of
# horizon with a non-standard name. Therefore we have to special case
# it.
GIT_REPO=${PROJECT}
RESOURCE=${PROJECT}-translations
PROJECT_DIR=${PROJECT}
if [ $PROJECT = "django_openstack_auth" ] ; then
    PROJECT=horizon
    PROJECT_DIR=openstack_auth
    RESOURCE=djangopo
fi

COMMIT_MSG="Imported Translations from Transifex"

git config user.name "OpenStack Proposal Bot"
git config user.email "openstack-infra@lists.openstack.org"
git config gitreview.username "proposal-bot"

git review -s

# See if there is an open change in the transifex/translations topic
# If so, get the change id for the existing change for use in the commit msg.
change_info=`ssh -p 29418 proposal-bot@review.openstack.org gerrit query --current-patch-set status:open project:$ORG/$GIT_REPO topic:transifex/translations owner:proposal-bot`
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
tx set --auto-local -r ${PROJECT}.${RESOURCE} "${PROJECT_DIR}/locale/<lang>/LC_MESSAGES/${PROJECT_DIR}.po" --source-lang en --source-file ${PROJECT_DIR}/locale/${PROJECT_DIR}.pot -t PO --execute

# Pull all upstream translations
tx pull -a -f
# Update the .pot file
python setup.py extract_messages
PO_FILES=`find ${PROJECT_DIR}/locale -name '*.po'`
if [ -n "$PO_FILES" ]
then
    # Use updated .pot file to update translations
    python setup.py update_catalog --no-fuzzy-matching  --ignore-obsolete=true
fi
# Add all changed files to git
git add $PROJECT_DIR/locale/*

# Don't send files where the only things which have changed are the
# creation date, the version number, the revision date, or comment
# lines.
for f in `git diff --cached --name-only`
do
  if [ `git diff --cached $f |egrep -v "(POT-Creation-Date|Project-Id-Version|PO-Revision-Date|^\+{3}|^\-{3}|^[-+]#)" | egrep -c "^[\-\+]"` -eq 0 ]
  then
      git reset -q $f
      git checkout -- $f
  fi
done

# Don't send a review if nothing has changed.
if [ `git diff --cached |wc -l` -gt 0 ]
then
    # Commit and review
    git commit -F- <<EOF
$COMMIT_MSG
EOF
    git review -t transifex/translations
fi
