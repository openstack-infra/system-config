#!/bin/bash -xe
# Copyright 2018 Red Hat, Inc.
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

BASE="/afs/.openstack.org/mirror/yum-puppetlabs"
MIRROR="rsync://rsync.puppet.com/packages"
K5START="k5start -t -f /etc/yum-puppetlabs.keytab service/yum-puppetlabs-mirror -- timeout -k 2m 30m"

if ! [ -f $BASE ]; then
    $K5START mkdir -p $BASE
fi

# We start a two-stage sync here for RPM
#
# The idea is to prevent temporary situations where metadata points to files
# which do not exist
#

# Exclude all metadata files
date --iso-8601=ns
echo "Running rsync only for packages update..."

# We don't need cisco-wrlinux arch in OpenStack Infra.
$K5START rsync -rlptDvz \
    --exclude="repodata/*" \
    --exclude="cisco-wrlinux" \
    $MIRROR/yum/ $BASE

# Now also transfer the metadata and delete afterwards
date --iso-8601=ns
echo "Running rsync with update..."
$K5START rsync -rlptDvz \
    --delete-after \
    --delete-excluded \
    --exclude="cisco-wrlinux" \
    $MIRROR/yum/ $BASE

# TODO(pabelanger): Validate rsync process

date --iso-8601=ns | $K5START tee $BASE/timestamp.txt
echo "rsync completed successfully, running vos release."
k5start -t -f /etc/afsadmin.keytab service/afsadmin -- vos release -v $MIRROR_VOLUME

date --iso-8601=ns
echo "Done."
