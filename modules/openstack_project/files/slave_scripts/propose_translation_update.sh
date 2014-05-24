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
COMMIT_MSG="Imported Translations from Transifex"

source /usr/local/jenkins/slave_scripts/common_translation_update.sh

setup_git 

setup_review "$ORG" "$PROJECT"
setup_translation
setup_project "$PROJECT"

# Pull upstream translations of files that are at least 75 %
# translated
tx pull -a -f --minimum-perc=75

# Update the .pot file
python setup.py extract_messages
PO_FILES=`find ${PROJECT}/locale -name '*.po'`
if [ -n "$PO_FILES" ]
then
    # Use updated .pot file to update translations
    python setup.py update_catalog --no-fuzzy-matching  --ignore-obsolete=true
fi
# Add all changed files to git
git add $PROJECT/locale/*

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
