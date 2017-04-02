#!/bin/bash

# Copyright 2016 IBM Corp.
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

set -e

REPREPRO_CONFIG=$1
MIRROR_VOLUME=$2
BASE=`cat ${REPREPRO_CONFIG}/options | grep base | cut -d' ' -f2`

UNREF_FILE=/var/run/reprepro/${MIRROR_VOLUME}.unreferenced-files
K5START="k5start -t -f /etc/reprepro.keytab service/reprepro -- timeout -k 2m 30m"
REPREPRO="$K5START reprepro --confdir $REPREPRO_CONFIG"

date --iso-8601=ns
echo "Obtaining reprepro tokens and running reprepro update"
$REPREPRO update

if [ -f $UNREF_FILE ] ; then
    date --iso-8601=ns
    echo "Cleaning up files made unreferenced on the last run"
    $REPREPRO deleteifunreferenced < $UNREF_FILE
fi

date --iso-8601=ns
echo "Saving list of newly unreferenced files for next time"
k5start -t -f /etc/reprepro.keytab service/reprepro -- bash -c "reprepro --confdir $REPREPRO_CONFIG dumpunreferenced > $UNREF_FILE"

date --iso-8601=ns
echo "Checking state of mirror"
$REPREPRO checkpool fast
$REPREPRO check

date --iso-8601=ns | $K5START tee $BASE/timestamp.txt
echo "reprepro completed successfully, running vos release."
k5start -t -f /etc/afsadmin.keytab service/afsadmin -- vos release -v $MIRROR_VOLUME

date --iso-8601=ns
echo "Done."
