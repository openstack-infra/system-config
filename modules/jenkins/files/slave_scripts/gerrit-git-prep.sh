#!/bin/bash -e

REVIEW_SITE=$1
GIT_SITE=$2

if [ -z "$REVIEW_SITE" ]
then
  echo "The git site name (eg 'https://review.openstack.org') must be the first argument."
  exit 1
fi

if [ -z "$GIT_SITE" ]
then
  echo "The git site name (eg 'http://zuul.openstack.org') must be the second argument."
  exit 1
fi

if [ -z "$ZUUL_REF" ]
then
    echo "This job may only be triggered by Zuul."
    exit 1
fi

if [ ! -z "$ZUUL_CHANGE" ]
then
    echo "Triggered by: $REVIEW_SITE/$ZUUL_CHANGE"
fi

set -x
if [[ ! -e .git ]]
then
    git clone $GIT_SITE/p/$ZUUL_PROJECT .
fi
git remote update || git remote update # attempt to work around bug #925790
git reset --hard
git clean -x -f -d -q

if [ -z "$ZUUL_NEWREV" ]
then
    git fetch $GIT_SITE/p/$ZUUL_PROJECT $ZUUL_REF
    git checkout FETCH_HEAD
    git reset --hard FETCH_HEAD
    git clean -x -f -d -q
else
    git checkout $ZUUL_NEWREV
    git reset --hard $ZUUL_NEWREV
    git clean -x -f -d -q
fi
