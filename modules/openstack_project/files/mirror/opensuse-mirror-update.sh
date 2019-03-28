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
MIRROR="rsync://mirror.us.leaseweb.net/opensuse"
OBS_MIRROR="rsync://provo-mirror.opensuse.org/opensuse/repositories"
OBS_REPOS=('Virtualization:/containers')
CLOUD_OBS_REPOS=('Cloud:/OpenStack:/Queens/openSUSE_Leap_42.3'
                'Cloud:/OpenStack:/Queens/openSUSE_Leap_15.0'
                'Cloud:/OpenStack:/Rocky/openSUSE_Leap_42.3'
                'Cloud:/OpenStack:/Rocky/openSUSE_Leap_15.0'
                'Cloud:/OpenStack:/Master/openSUSE_Leap_15.0')
K5START="k5start -t -f /etc/opensuse.keytab service/opensuse-mirror -- timeout -k 2m 30m"

# NOTE(hwoarang): Ensure old distros are not mirrored aymore
for REPO in distribution/leap/42.2 update/leap/42.2 \
        repositories/Cloud:/OpenStack:/Master/openSUSE_Leap_42.3 ; do
    if [ -d $BASE/$REPO ]; then
        $K5START rm -rf $BASE/$REPO
    fi
done

# NOTE(hwoarang): 15.0 is newer than 42.3.
for DISTVER in 42.3 15.0; do
    REPO=distribution/leap/$DISTVER
    if ! [ -f $BASE/$REPO ]; then
        $K5START mkdir -p $BASE/$REPO
    fi

    date --iso-8601=ns
    echo "Running rsync distribution $DISTVER ..."
    $K5START rsync -rlptDvz \
        --delete --stats \
        --delete-excluded \
        --exclude="iso" \
        $MIRROR/$REPO/ $BASE/$REPO/

    REPO=update/leap/$DISTVER
    if ! [ -f $BASE/$REPO ]; then
        $K5START mkdir -p $BASE/$REPO
    fi

    date --iso-8601=ns
    echo "Running rsync updates $DISTVER ..."
    $K5START rsync -rlptDvz \
        --delete --stats \
        --delete-excluded \
        --exclude="src/" \
        --exclude="nosrc/" \
        $MIRROR/$REPO/ $BASE/$REPO/

    date --iso-8601=ns
    for obs_repo in ${OBS_REPOS[@]}; do
        REPO=repositories/${obs_repo}/openSUSE_Leap_${DISTVER}/
        if ! [ -f $BASE/$REPO ]; then
            $K5START mkdir -p $BASE/$REPO
        fi
        echo "Running rsync ${obs_repo} $DISTVER ..."
        $K5START rsync -rlptDvz \
            --delete --stats \
            --delete-excluded \
            --exclude="src/" \
            --exclude="nosrc/" \
            $OBS_MIRROR/$obs_repo/openSUSE_Leap_${DISTVER}/ $BASE/$REPO/
    done

done

date --iso-8601=ns
for obs_repo in ${CLOUD_OBS_REPOS[@]}; do
    REPO=repositories/${obs_repo}/
    if ! [ -f $BASE/$REPO ]; then
        $K5START mkdir -p $BASE/$REPO
    fi
    echo "Running rsync ${obs_repo} ..."
    $K5START rsync -rlptDvz \
        --delete --stats \
        --delete-excluded \
        --exclude="src/" \
        --exclude="nosrc/" \
        $OBS_MIRROR/$obs_repo/ $BASE/$REPO
done

REPO=tumbleweed
if ! [ -f $BASE/$REPO ]; then
    $K5START mkdir -p $BASE/$REPO/repo/oss/
fi

date --iso-8601=ns
echo "Running rsync distribution $REPO ..."
# TW is large and can have failures, be more resilient
$K5START rsync -rlptDvz \
    --delete --stats \
    --delete-excluded \
    --exclude="i586" \
    --ignore-errors \
    $MIRROR/$REPO/repo/oss/ $BASE/$REPO/repo/oss/ || :

REPO=update/tumbleweed
if ! [ -f $BASE/$REPO ]; then
    $K5START mkdir -p $BASE/$REPO
fi

date --iso-8601=ns
echo "Running rsync distribution $REPO ..."
$K5START rsync -rlptDvz \
    --timeout=600 \
    --delete --stats \
    --delete-excluded \
    --exclude="i586" \
    --ignore-errors \
    rsync://rsync.opensuse.org/buildservice-repos-main/openSUSE:/Factory:/Update/standard/ \
    $BASE/$REPO || :

date --iso-8601=ns | $K5START tee $BASE/timestamp.txt
echo "rsync completed successfully, running vos release."
k5start -t -f /etc/afsadmin.keytab service/afsadmin -- vos release -v $MIRROR_VOLUME

date --iso-8601=ns
echo "Done."
