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

COMMIT_MSG="Updated from global requirements"
TOPIC="openstack/requirements"
USERNAME=${USERNAME:-$USER}
BRANCH=${ZUUL_BRANCH:-master}

git config user.name "OpenStack Jenkins"
git config user.email "jenkins@openstack.org"
git config gitreview.username $USERNAME

for PROJECT in $(cat projects.txt); do

    # See if there is an open change in the openstack/requirements topic
    # If so, get the change id for the existing change for use in the
    # commit msg.
    change_info=$(ssh -p 29418 review.openstack.org gerrit query --current-patch-set status:open project:$PROJECT topic:$TOPIC owner:$USERNAME branch:$BRANCH)
    previous=$(echo "$change_info" | grep "^  number:" | awk '{print $2}')
    if [ "x${previous}" != "x" ] ; then
        change_id=$(echo "$change_info" | grep "^change" | awk '{print $2}')
        # read return a non zero value when it reaches EOF. Because we use a
        # heredoc here it will always reach EOF and return a nonzero value.
        # Disable -e temporarily to get around the read.
        set +e
        read -d '' COMMIT_MSG <<EOF
$COMMIT_MSG

Change-Id: $change_id
EOF
        set -e
    fi

    git clone --depth=1 ssh://$USERNAME@review.openstack.org:29418/$PROJECT.git

    PROJECT_DIR=$(basename $PROJECT)
    python update.py $PROJECT_DIR

    pushd $PROJECT_DIR
    git review -s

    if ! git diff --quiet ; then
        # Commit and review
        git commit -a -F- <<EOF
$COMMIT_MSG
EOF
        git review -t $TOPIC $BRANCH
    fi
    popd

done
