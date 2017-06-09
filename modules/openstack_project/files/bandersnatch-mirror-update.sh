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

# Set up logging, see:
# http://www.tldp.org/LDP/abs/html/x17974.html
LOG_FILE=$1
# Open STDOUT as $LOG_FILE file for write appending.
exec 1>>$LOG_FILE
# Redirect STDERR to STDOUT
exec 2>&1

START_TIME=$(date --iso-8601=ns)
echo $START_TIME
echo "Obtaining bandersnatch tokens and running bandersnatch."
# Note that the set -e is important above as it will cause us
# to not do a vos release if bandersnatch fails. Below we check
# additional conditions on whether or not to do a vos release.
k5start -t -f /etc/bandersnatch.keytab service/bandersnatch -- timeout -k 2m 4h run-bandersnatch

# Make sure logs made it to disk
sync

# This is what it looks like when bandersnatch logs it.
# 2017-06-09 19:40:02,545 INFO: Syncing package: shodan (serial 2939083)
# Need to get package name (shodan) and compare it to upper-constraints in
# openstack/requirements (all branches)

# We get the list of packages out of our own log. There is a lot happening
# with sed below so lets talk about it.
# First we don't print every line we process (-n) we only print those lines
# that match using the trailing /p
# Next we only match beginning at our start time to the end of the file
# (/from_pattern/,to_pattern)
# Then we oonly look for lines that say Syncing package as these actually
# give us the package name. We extract the package name from here and print
# it.
sed -n -e "/$START_TIME/,\$s/.*Syncing\spackage:\s\(.*\)\s(serial\s[0-9]\+)/\1/p" $LOG_FILE | sort -u > /tmp/bandersnatch_updated_packages

LAST_VOS_RELEASE=$(vos examine mirror.pypi.readonly -format | grep 'updateDate' | head -1 | sed -e 's/updateDate\s\([0-9]\+\)\s.*/\1/')
NOW=$(date +%s)
DELTA=$((NOW - LAST_VOS_RELEASE))

NEED_RELEASE="no"
if [[ "$DELTA" -gt "14400" ]] ; then
    NEED_RELEASE="yes"
elif [[ $(wc -l /tmp/bandersnatch_updated_packages | cut -d' ' -f 1) -gt "512" ]] ; then
    # If there are a lot of packages updated just go ahead and sync.
    NEED_RELEASE="yes"
else
    date --iso-8601=ns
    echo "Checking package updates against requirements"

    REPO_PATH=/opt/pypi_mirror_update/requirements
    if ! [ -d $REPO_PATH ] ; then
        mkdir -p $REPO_PATH
    fi

    export GIT_DIR="$REPO_PATH/.git"
    if ! [ -d $GIT_DIR ] ; then
        git clone https://git.openstack.org/openstack/requirements $REPO_PATH
    fi

    # Ensure repo contents are up to date
    git remote update
    git prune

    PACKAGES=$(cat /tmp/bandersnatch_updated_packages)
    for BRANCH in `git branch -a | grep 'remotes/origin' | grep -v 'HEAD'` ; do
        # Make best effort at listing packages but don't fail if we can't
        # list then on a specific branch for some reason.
        set +e
        git show "$BRANCH:upper-constraints.txt" > /tmp/pypi-update-constraints
        git show "$BRANCH:blacklist.txt" > /tmp/pypi-update-blacklist
        set -e
        for PACKAGE in $PACKAGES ; do
            if grep -q -i "$PACKAGE" /tmp/pypi-update-constraints /tmp/pypi-update-blacklist ; then
                NEED_RELEASE="yes"
                break
            fi
        done
        if [[ "$NEED_RELEASE" == "yes" ]] ; then
            break
        fi
    done

    unset GIT_DIR
fi

date --iso-8601=ns
if [[ "$NEED_RELEASE" == "yes" ]] ; then
    echo "Bandersnatch completed successfully, running vos release."
    k5start -t -f /etc/afsadmin.keytab service/afsadmin -- vos release -v mirror.pypi
else
    # We minimize vos releases as a release causes the remote AFS caches to
    # update file metadata on reads. This significantly tanks the performance
    # of remote caches on the other side of the world. Note this appears to
    # happen even if vos release doesn't update any data.
    echo "Bandersnatch completed successfully, not updating as no constrained package was updated."
fi

date --iso-8601=ns
echo "Done."
