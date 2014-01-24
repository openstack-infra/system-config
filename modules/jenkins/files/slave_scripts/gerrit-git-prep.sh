#!/bin/bash -e

# Copyright 2011-2014 OpenStack Foundation
# Copyright 2012-2013 Hewlett-Packard Development Company, L.P.
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

GERRIT_SITE=$1
GIT_ORIGIN=$2

if [ -z "$GERRIT_SITE" ]
then
  echo "The gerrit site name (eg 'https://review.openstack.org') must be the first argument."
  exit 1
fi

if [ -z "$ZUUL_URL" ]
then
  echo "The ZUUL_URL must be provided."
  exit 1
fi

if [ -z "$GIT_ORIGIN" ] || [ -n "$ZUUL_NEWREV" ]
then
    GIT_ORIGIN="$GERRIT_SITE/p"
    # git://git.openstack.org/
    # https://review.openstack.org/p
fi

if [ -z "$ZUUL_REF" ]
then
    echo "This job may only be triggered by Zuul."
    exit 1
fi

if [ ! -z "$ZUUL_CHANGE" ]
then
    echo "Triggered by: $GERRIT_SITE/$ZUUL_CHANGE"
fi

set -x
if [[ ! -e .git ]]
then
    ls -a
    rm -fr .[^.]* *
    if [ -d /opt/git/$ZUUL_PROJECT/.git ]
    then
        git clone file:///opt/git/$ZUUL_PROJECT .
    else
        git clone $GIT_ORIGIN/$ZUUL_PROJECT .
    fi
fi
git remote set-url origin $GIT_ORIGIN/$ZUUL_PROJECT

# attempt to work around bugs 925790 and 1229352
if ! git remote update
then
    echo "The remote update failed, so garbage collecting before trying again."
    git gc
    git remote update
fi

git reset --hard
if ! git clean -x -f -d -q ; then
    sleep 1
    git clean -x -f -d -q
fi

if [ -z "$ZUUL_NEWREV" ]
then
    git fetch $ZUUL_URL/$ZUUL_PROJECT $ZUUL_REF
    git checkout FETCH_HEAD
    git reset --hard FETCH_HEAD
    if ! git clean -x -f -d -q ; then
        sleep 1
        git clean -x -f -d -q
    fi
else
    git checkout $ZUUL_NEWREV
    git reset --hard $ZUUL_NEWREV
    if ! git clean -x -f -d -q ; then
        sleep 1
        git clean -x -f -d -q
    fi
fi

if [ -f .gitmodules ]
then
    git submodule init
    git submodule sync
    git submodule update --init
fi
