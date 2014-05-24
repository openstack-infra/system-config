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
# User visible strings
tx set --auto-local -r ${PROJECT}.${PROJECT}-translations "${PROJECT}/locale/<lang>/LC_MESSAGES/${PROJECT}.po" --source-lang en --source-file ${PROJECT}/locale/${PROJECT}.pot -t PO --execute

# Strings for various log levels
LEVELS="info warning error critical"
# Keywords for each log level:
declare -A LKEYWORD
LKEYWORD['info']='_LI'
LKEYWORD['warning']='_LW'
LKEYWORD['error']='_LE'
LKEYWORD['critical']='_LC'
for level in $LEVELS ; do
  # Bootstrapping: Create file if it does not exist yet, otherwise "tx
  # set" will fail
  if [ ! -e  ${PROJECT}/locale/${PROJECT}-log-${level}.pot ]
  then
    touch ${PROJECT}/locale/${PROJECT}-log-${level}.pot
  fi
  tx set --auto-local -r ${PROJECT}.${PROJECT}-log-${level}-translations \
    "${PROJECT}/locale/<lang>/LC_MESSAGES/${PROJECT}-log-${level}.po" \
    --source-lang en \
    --source-file ${PROJECT}/locale/${PROJECT}-log-${level}.pot -t PO \
    --execute
done

# Update the .pot files
python setup.py extract_messages
for level in $LEVELS ; do
  python setup.py extract_messages --no-default-keywords \
    --keyword ${LKEYWORD[$level]} \
    --output-file ${PROJECT}/locale/${PROJECT}-log-${level}.pot
done

PO_FILES=`find ${PROJECT}/locale -name "${PROJECT}.po"`
if [ -n "$PO_FILES" ]
then
    # Use updated .pot file to update translations
    python setup.py update_catalog --no-fuzzy-matching --ignore-obsolete=true
fi
# We cannot run update_catlog for the log files, since there is no
# option to specify the keyword and thus an update_catalog run would
# add the messages with the default keywords. Therefore use msgmerge
# directly.
for level in $LEVELS ; do
  PO_FILES=`find ${PROJECT}/locale -name "${PROJECT}-log-${level}.po"`
  if [ -n "$PO_FILES" ]
  then
    for f in $PO_FILES ; do
	echo "Updating $f"
	msgmerge --update --no-fuzzy-matching $f ${PROJECT}/locale/${PROJECT}-log-${level}.pot
    done
  fi
done

# Add all changed files to git
git add $PROJECT/locale/*

if [ ! `git diff-index --quiet HEAD --` ]
then
    # Push .pot changes to transifex
    tx --debug --traceback push -s -r ${PROJECT}.${PROJECT}-translations
    for level in $LEVELS ; do
        # Only push if there is actual content in the file. We check
        # that the file contains at least one non-empty msgid string.
        if grep -q 'msgid "[^"]' ${PROJECT}/locale/${PROJECT}-log-${level}.pot
        then
            tx --debug --traceback push -s -r ${PROJECT}.${PROJECT}-log-${level}-translations
        fi
    done
fi
