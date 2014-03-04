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
COMMIT_MSG="Updated sample config file"
TOPIC="config/sample_config"

git config user.name "OpenStack Jenkins"
git config user.email "jenkins@openstack.org"
git config gitreview.username "jenkins"

git review -s

# See if there is an open change in the 'config/sample_config' topic
# If so, get the change id for the existing change for use in the commig msg.
change_info=`ssh -p 29418 review.openstack.org gerrit query --current-patch-set status:open project:$ORG/$PROJECT topic:$TOPIC owner:jenkins`
previous=`echo "$change_info" | grep "^change" | awk '{print $2}'`
if [ "x${previous}" != "x" ]; then
    change_id=`echo "$change_info" | grep "^change" | awk '{print $2}'`
    # read return a non zero value when it reaches EOF. Because we use a
    # heredoc here it will always reach EOF and return a nonzero valu.
    # Disable -e temporarily to get around the read.
    set +e
    read -d '' COMMIT_MSG <<EOF
Updated Sample Config File

Change-Id: $change_id
EOF
    set -e
fi

# run the sample config generation
/usr/local/jenkins/slave_scripts/run-tox.sh sample_config $ORG $PROJECT

git add etc/*

if [ `git diff --cached egrep -c "^[\-\+]"` -gt 0 ];
then
    git commit -F- <<EOF
$COMMIT_MSG
EOF

    git review -t $TOPIC
fi
