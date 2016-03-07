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

BASE="/afs/.openstack.org/mirror/centos"
MIRROR="rsync://mirror.sfo12.us.leaseweb.net"

UNREF_FILE=/var/run/epel.unreferenced-files

if ! [ -f $BASE/epel ]; then
    mkdir -p $BASE/epel
fi

echo "Running repo update"
rsync -vaH \
    --exclude-from='epel.txt' \
    --numeric-ids \
    $MIRROR/epel/ $BASE/epel/

if [ -f $UNREF_FILE ]; then
    echo "Cleaning up files made unreferenced on the last run"
    cd $BASE/epel
    cat $UNREF_FILE | xargs rm -rf
    cd ../..
fi

# EPEL
echo "Saving list of newly unreferenced files for next time"
rsync -vaH \
    --exclude-from='epel.txt' \
    --numeric-ids \
    --delete-before \
    --existing \
    --ignore-existing \
    --dry-run \
    $MIRROR/epel/ $BASE/epel/ | grep deleting | cut -d' ' -f2 > $UNREF_FILE

echo "Generate mirror"
createrepo $BASE/epel/7/x86_64/

