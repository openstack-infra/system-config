#!/bin/bash -xe
# Copyright 2017 SUSE Linux GmbH
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

BASE="/afs/.openstack.org/mirror/opensuse"
MIRROR="rsync://mirrors.kernel.org"
K5START="k5start -t -f /etc/opensuse.keytab service/opensuse-mirror -- timeout -k 2m 30m"

REPO=leap/42.2
if ! [ -f $BASE/$REPO ]; then
    $K5START mkdir -p $BASE/$REPO
fi

date --iso-8601=ns
echo "Running rsync releases..."
$K5START rsync -rlptDvz \
    --delete \
    --delete-excluded \
    --exclude="iso" \
    $MIRROR/opensuse/distribution/$REPO/ $BASE/$REPO/

REPO=update/leap/42.2
if ! [ -f $BASE/$REPO ]; then
    $K5START mkdir -p $BASE/$REPO
fi

date --iso-8601=ns
echo "Running rsync updates..."
$K5START rsync -rlptDvz \
    --delete \
    --delete-excluded \
    --exclude="src/" \
    --exclude="nosrc/" \
    $MIRROR/opensuse/update/$REPO/ $BASE/$REPO/

date --iso-8601=ns | $K5START tee $BASE/timestamp.txt
echo "rsync completed successfully, running vos release."
k5start -t -f /etc/afsadmin.keytab service/afsadmin -- vos release -v $MIRROR_VOLUME

date --iso-8601=ns
echo "Done."
