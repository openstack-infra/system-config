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

# The script is to pull the translations from Transifex,
# and push to Gerrit.

ORG="openstack"
PROJECT=$1

source /usr/local/jenkins/slave_scripts/common_translation_update.sh

init_manuals "$PROJECT"

setup_git
setup_review "$ORG" "$PROJECT"
setup_translation

setup_manuals

# Pull upstream translations of files that are at least 75 %
# translated
tx pull -a -f --minimum-perc=75

# The common directory is used by the other guides, let's be more
# liberal here since teams might only translate the files used by a
# single guide. We use 8 % since that downloads the currently
# translated files.
if [ $PROJECT = "openstack-manuals" ] ; then
    tx pull -f  --minimum-perc=8 -r openstack-manuals-i18n.common
fi

# Add imported upstream translations to git
for FILE in ${DocFolder}/*
do
    DOCNAME=${FILE#${DocFolder}/}
    if [ -d ${DocFolder}/${DOCNAME}/locale ]
    then
        git add ${DocFolder}/${DOCNAME}/locale/*
    fi
done

filter_commits

send_patch
