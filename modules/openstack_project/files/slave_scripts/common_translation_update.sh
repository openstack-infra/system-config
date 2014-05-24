#!/bin/bash -xe 
# Common code used by propose_translation_update.sh and
# upstream_translation_update.sh

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


function setup_translation ()
{

    # Initialize the transifex client, if there's no .tx directory
    if [ ! -d .tx ] ; then
	tx init --host=https://www.transifex.com
    fi
}

function setup_project ()
{
    project=$1

    tx set --auto-local -r ${project}.${project}-translations \
	"${project}/locale/<lang>/LC_MESSAGES/${project}.po" \
	--source-lang en \
	--source-file ${project}/locale/${project}.pot -t PO \
	--execute
}

function setup_git ()
{
    git config user.name "OpenStack Proposal Bot"
    git config user.email "openstack-infra@lists.openstack.org"
    git config gitreview.username "proposal-bot"
}
