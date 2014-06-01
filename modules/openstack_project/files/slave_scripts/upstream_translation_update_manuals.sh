#!/bin/bash -xe

# Copyright 2013 IBM Corp.
#
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

# The script is to push the updated PoT to Transifex.

PROJECT=$1

if [ ! `echo $ZUUL_REFNAME | grep master` ]
then
    exit 0
fi

source /usr/local/jenkins/slave_scripts/common_translation_update.sh

init_manuals "$PROJECT"

setup_git
setup_translation

setup_manuals

if [ ! `git diff --cached --quiet HEAD --` ]
then
    # Push .pot changes to transifex
    tx --debug --traceback push -s
fi
