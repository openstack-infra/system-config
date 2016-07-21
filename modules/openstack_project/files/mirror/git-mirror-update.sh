#!/bin/bash -xe
# Copyright 2016 Red Hat, Inc.
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

FILENAME=$1
MIRROR_VOLUME=$2

BASE="/afs/.openstack.org/mirror/git"
K5START="k5start -t -f /etc/git.keytab service/git-mirror -- timeout -k 2m 30m"
TOP_LEVEL=`pwd`

date --iso-8601=ns
echo "Running git..."
while read -r line; do
    cd $TOP_LEVEL
    REPO_PATH=`echo $line | awk -F// '{print $NF}'`.git
    if ! [ -d $REPO_PATH ]; then
        echo "Initial mirror of $REPO_PATH"
        $K5START git clone --mirror $line $REPO_PATH
    else
        cd $REPO_PATH
        $K5START git fetch --all -p
    fi
done < "$1"

date --iso-8601=ns
echo "git completed successfully, running vos release."
k5start -t -f /etc/afsadmin.keytab service/afsadmin -- vos release -v $MIRROR_VOLUME

date --iso-8601=ns
echo "Done."
