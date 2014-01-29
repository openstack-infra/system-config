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

INITIAL_COMMIT_MSG="Updated from global requirements"
TOPIC="openstack/requirements"
USERNAME=${USERNAME:-$USER}
BRANCH=$ZUUL_REF
ALL_SUCCESS=0

if [ -z "$BRANCH" ] ; then
    echo "No branch set, exiting."
    exit 1
fi

git config user.name "OpenStack Jenkins"
git config user.email "jenkins@openstack.org"
git config gitreview.username $USERNAME

for PROJECT in $(cat projects.txt); do

    change_id=""
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
        # The reason we use read is to allow for multiline variable content
        # and variable interpolation. Simply double quoting a string across
        # multiple lines removes the newlines.
        set +e
        read -d '' COMMIT_MSG <<EOF
$INITIAL_COMMIT_MSG

Change-Id: $change_id
EOF
        set -e
    else
        COMMIT_MSG=$INITIAL_COMMIT_MSG
    fi

    PROJECT_DIR=$(basename $PROJECT)
    rm -rf $PROJECT_DIR
    git clone ssh://$USERNAME@review.openstack.org:29418/$PROJECT.git
    pushd $PROJECT_DIR

    # make sure the project even has this branch
    if git branch -a | grep -q "^  remotes/origin/$BRANCH$" ; then
        git checkout origin/${BRANCH}
        git review -s
        popd

        python update.py $PROJECT_DIR

        pushd $PROJECT_DIR
        if ! git diff --exit-code HEAD ; then
            # Commit and review
            git_args="-a -F-"
            git commit $git_args <<EOF
$COMMIT_MSG
EOF
            # Do error checking manually to ignore one class of failure.
            set +e
            OUTPUT=$(git review -t $TOPIC $BRANCH)
            RET=$?
            [[ "$RET" -eq "0" || "$OUTPUT" =~ "no new changes" ]]
            SUCCESS=$?
            [[ "$SUCCESS" -eq "0" && "$ALL_SUCCESS" -eq "0" ]]
            ALL_SUCCESS=$?
            set -e
        fi
    fi

    popd
done

exit $ALL_SUCCESS
