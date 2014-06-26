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

TAG=$1

# Only merge tag if there is one *proposed* branch at origin
PROPOSED=$(git branch -r | grep proposed) || exit 0

# If there is more than one *proposed* branch at origin, that's an error
if [ "$(echo $PROPOSED | wc -w)" != "1" ]
then
    echo "Multiple proposed branches found:"
    echo $PROPOSED
    exit 1
fi

# Only merge release tag if it's on the proposed branch HEAD
if $(git tag --contains origin/${PROPOSED:2} | grep "^$TAG$" >/dev/null)
then
    git config user.name "OpenStack Proposal Bot"
    git config user.email "openstack-infra@lists.openstack.org"
    git config gitreview.username "proposal-bot"

    git review -s
    git checkout master
    git reset --hard origin/master
    git merge --no-edit -s ours $TAG
    # Get a Change-Id
    GIT_EDITOR=true git commit --amend
    git review -R -y -t merge/release-tag
fi
