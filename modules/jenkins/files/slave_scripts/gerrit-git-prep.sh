#!/bin/bash -e

GERRIT_SITE=$1
GIT_ORIGIN=$2

# TODO(jeblair): Remove once the arg list is changed in jjb macros
if [ ! -z $3 ]
then
    GIT_ORIGIN=$3
fi

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
