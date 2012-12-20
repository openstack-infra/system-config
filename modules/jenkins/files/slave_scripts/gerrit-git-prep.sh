#!/bin/bash -e

GERRIT_SITE=$1
ZUUL_SITE=$2

if [ -z "$GERRIT_SITE" ]
then
  echo "The gerrit site name (eg 'https://review.openstack.org') must be the first argument."
  exit 1
fi

if [ -z "$ZUUL_SITE" ]
then
  echo "The zuul site name (eg 'http://zuul.openstack.org') must be the second argument."
  exit 1
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
    git clone $GERRIT_SITE/p/$ZUUL_PROJECT .
fi
git remote set-url origin $GERRIT_SITE/p/$ZUUL_PROJECT
git remote update || git remote update # attempt to work around bug #925790
git reset --hard
git clean -x -f -d -q

if [ -z "$ZUUL_NEWREV" ]
then
    git fetch $ZUUL_SITE/p/$ZUUL_PROJECT $ZUUL_REF
    git checkout FETCH_HEAD
    git reset --hard FETCH_HEAD
    git clean -x -f -d -q
else
    git checkout $ZUUL_NEWREV
    git reset --hard $ZUUL_NEWREV
    git clean -x -f -d -q
fi
