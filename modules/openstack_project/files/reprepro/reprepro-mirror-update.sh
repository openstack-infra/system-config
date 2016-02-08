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

UNREF_FILE=/var/run/reprepro/unreferenced-files
REPREPRO='reprepro --confdir /etc/reprepro'

echo "Obtaining reprepro tokens and running reprepro update"
k5start -t -f /etc/reprepro.keytab service/reprepro -- timeout -k 2m 30m $REPREPRO update

if [ -f $UNREF_FILE ] ; then
    echo "Cleaning up files made unreferenced on the last run"
    k5start -t -f /etc/reprepro.keytab service/reprepro -- timeout -k 2m 30m $REPREPRO deleteifunreferenced < $UNREF_FILE
fi

echo "Saving list of newly unreferenced files for next time"
k5start -t -f /etc/reprepro.keytab service/reprepro --$REPREPRO dumpunreferenced > $UNREF_FILE

echo "Checking state of mirror"
k5start -t -f /etc/reprepro.keytab service/reprepro --$REPREPRO checkpool fast
k5start -t -f /etc/reprepro.keytab service/reprepro --$REPREPRO check

echo "reprepro completed successfully, running reprepro export."
k5start -t -f /etc/afsadmin.keytab service/afsadmin -- vos release -v mirror.apt

echo "Done."
