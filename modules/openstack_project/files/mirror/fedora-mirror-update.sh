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

BASE="/afs/.openstack.org/mirror/fedora"
# NOTE(pabelanger): #fedora-admin:
# tibbs | I run pubmirror[12].math.uh.edu.
# tibbs | It polls the masters every ten minutes.
MIRROR="rsync://pubmirror1.math.uh.edu/fedora-buffet/fedora/linux"
K5START="k5start -t -f /etc/fedora.keytab service/fedora-mirror -- timeout -k 2m 30m"

for REPO in releases/27 releases/28; do
    if ! [ -f $BASE/$REPO ]; then
        $K5START mkdir -p $BASE/$REPO
    fi

    date --iso-8601=ns
    echo "Running rsync releases..."
    $K5START rsync -rlptDvz \
        --delete \
        --delete-excluded \
        --exclude="Cloud/x86_64/images/*.box" \
        --exclude="CloudImages/x86_64/images/*.box" \
        --exclude="Container" \
        --exclude="Docker" \
        --exclude="aarch64/" \
        --exclude="armhfp/" \
        --exclude="source/" \
        --exclude="Server" \
        --exclude="Spins" \
        --exclude="Workstation" \
        --exclude="x86_64/debug/" \
        --exclude="x86_64/drpms/" \
        $MIRROR/$REPO/ $BASE/$REPO/
done

for REPO in updates/27 updates/28 ; do
    if ! [ -f $BASE/$REPO ]; then
        $K5START mkdir -p $BASE/$REPO
    fi

    date --iso-8601=ns
    echo "Running rsync updates..."
    $K5START rsync -rlptDvz \
        --delete \
        --delete-excluded \
        --exclude="aarch64/" \
        --exclude="armhfp/" \
        --exclude="i386/" \
        --exclude="source/" \
        --exclude="SRPMS/" \
        --exclude="x86_64/debug" \
        --exclude="x86_64/drpms" \
        $MIRROR/$REPO/ $BASE/$REPO/
done

MIRROR="rsync://pubmirror1.math.uh.edu/fedora-buffet/alt/atomic"

if ! [ -f $BASE/atomic ]; then
    $K5START mkdir -p $BASE/atomic
fi

echo "Running rsync atomic..."
date --iso-8601=ns
$K5START rsync -rltDvz \
    --delete \
    --delete-excluded \
    --exclude="testing/" \
    --exclude="Atomic/" \
    --exclude="CloudImages/x86_64/images/*.raw.xz" \
    --exclude="CloudImages/x86_64/images/*.box" \
    $MIRROR/ $BASE/atomic/

# TODO(pabelanger): Validate rsync process

date --iso-8601=ns | $K5START tee $BASE/timestamp.txt
echo "rsync completed successfully, running vos release."
k5start -t -f /etc/afsadmin.keytab service/afsadmin -- vos release -v $MIRROR_VOLUME

date --iso-8601=ns
echo "Done."
