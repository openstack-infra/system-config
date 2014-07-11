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

source /usr/local/jenkins/slave_scripts/common_translation_update.sh

setup_git
setup_translation
setup_project "$PROJECT"

setup_loglevel_vars
setup_loglevel_project "$PROJECT"

extract_messages_log "$PROJECT"

# Add all changed files to git
git add $PROJECT/locale/*

if [ ! `git diff-index --quiet HEAD --` ]
then
    # Push .pot changes to transifex

    # Transifex project name does not include "."
    tx_project=${PROJECT/\./}
    tx --debug --traceback push -s -r ${tx_project}.${tx_project}-translations
    for level in $LEVELS ; do
        # Only push if there is actual content in the file. We check
        # that the file contains at least one non-empty msgid string.
        if grep -q 'msgid "[^"]' ${PROJECT}/locale/${PROJECT}-log-${level}.pot
        then
            tx --debug --traceback push -s \
                -r ${tx_project}.${tx_project}-log-${level}-translations
        fi
    done
fi
