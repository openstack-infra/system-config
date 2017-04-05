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

BASE="/afs/.openstack.org/mirror/epel"
# NOTE(pabelanger): #fedora-admin:
# tibbs | I run pubmirror[12].math.uh.edu.
# tibbs | It polls the masters every ten minutes.
MIRROR="rsync://pubmirror1.math.uh.edu/fedora-buffet/epel"
K5START="k5start -t -f /etc/epel.keytab service/epel-mirror -- timeout -k 2m 30m"

REPO=7
if ! [ -f $BASE/$REPO ]; then
    $K5START mkdir -p $BASE/$REPO
fi

date --iso-8601=ns
echo "Running rsync..."
$K5START rsync -rlptDvz \
    --delete \
    --delete-excluded \
    --exclude="SRPMS" \
    --exclude="aarch64" \
    --exclude="ppc64" \
    --exclude="ppc64le" \
    --exclude="x86_64/debug" \
    --exclude="x86_64/repoview" \
    $MIRROR/$REPO/ $BASE/$REPO/

# NOTE(pabelanger): Validate repomd.xml with upstream release version, this is
# to help protect when our upstream mirror (mirrors.kernel.org) is out of sync
# with its upstream mirror.
REPOMD="x86_64/repodata/repomd.xml"
SHA1SUM=`curl -s https://dl.fedoraproject.org/pub/epel/7/$REPOMD | sha1sum | cut -d' ' -f1`
echo "$SHA1SUM $BASE/$REPO/$REPOMD" | sha1sum -c -

date --iso-8601=ns | $K5START tee $BASE/timestamp.txt
echo "rsync completed successfully, running vos release."
k5start -t -f /etc/afsadmin.keytab service/afsadmin -- vos release -v $MIRROR_VOLUME

date --iso-8601=ns
echo "Done."
