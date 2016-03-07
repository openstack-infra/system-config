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

MIRROR_VOLUME=$1

BASE="/afs/.openstack.org/mirror/centos"
MIRROR="rsync://mirror.sfo12.us.leaseweb.net"
UNREF_FILE=/var/run/${MIRROR_VOLUME}.unreferenced-files
K5START="k5start -t -f /etc/rpmmirror.keytab service/rpmmirror -- timeout -k 2m 30m"

REPO=7/os/x86_64

if ! [ -f $BASE/$REPO ]; then
    mkdir -p $BASE/$REPO
fi

echo "Running repo update for os"
# NOTE(pabelanger): We don't need to cache unreferenced list, as it will never
# change.
$K5START rsync -vaH \
    --numeric-ids \
    --delete-before \
    $MIRROR/centos/$REPO/ $BASE/$REPO/

REPO=7/updates/x86_64

if ! [ -f $BASE/$REPO ]; then
    mkdir -p $BASE/$REPO
fi

echo "Running repo update for updates"
$K5START rsync -vaH \
    --numeric-ids \
    $MIRROR/centos/$REPO/ $BASE/$REPO/

if [ -f $UNREF_FILE ]; then
    echo "Cleaning up files made unreferenced on the last run"
    cd $BASE/$REPO
    cat $UNREF_FILE | $K5START bash -c "xargs rm -rf"
    cd $BASE
fi

# centos
echo "Saving list of newly unreferenced files for next time"
$K5START rsync -vaH \
    --numeric-ids \
    --delete-before \
    --existing \
    --ignore-existing \
    --dry-run \
    $MIRROR/centos/$REPO/ $BASE/$REPO/ | grep deleting | cut -d' ' -f2 > $UNREF_FILE

echo "Generate mirror"
$K5START createrepo $BASE/$REPO/

echo "rsyc completed successfully, running vos release."
k5start -t -f /etc/afsadmin.keytab service/afsadmin -- vos release -v $MIRROR_VOLUME

echo "Done."
