#!/bin/bash -e

SITE=$1
if [ -z "$SITE" ]
then
  echo "The site name (eg 'review.openstack.org') must be the first argument."
  exit 1
fi

if [ -z "$ZUUL_NEWREV" ] && [ -z "$ZUUL_REF" ]
then
    echo "This job may only be triggered by Zuul."
    exit 1
fi

if [ ! -z "$ZUUL_CHANGE" ]
then
    echo "Triggered by: https://$SITE/$ZUUL_CHANGE patchset $ZUUL_PATCHSET"
fi

if [ ! -z "$ZUUL_REFNAME" ]
then
    echo "Triggered by: $ZUUL_REFNAME updated with $ZUUL_NEWREV"
fi

echo "Pipeline: $ZUUL_PIPELINE"

set -x
if [[ ! -e .git ]]
then
    git clone https://$SITE/p/$ZUUL_PROJECT .
fi

git remote update || git remote update # attempt to work around bug #925790
git reset --hard
git clean -x -f -d -q

if [ -z "$ZUUL_NEWREV" ]
then
    MAX_ATTEMPTS=${3:-3}
    COUNT=0
    until git fetch https://$SITE/p/$ZUUL_PROJECT $ZUUL_REF
    do
        COUNT=$(($COUNT + 1))
        logger -p user.warning -t 'gerrit-git-prep' FAILED: git fetch https://$SITE/p/$ZUUL_PROJECT $ZUUL_REF COUNT: $COUNT
        if [ $COUNT -eq $MAX_ATTEMPTS ]
        then
            break
        fi
        SLEEP_TIME=$((30 + $RANDOM % 60))
        logger -p user.warning -t 'gerrit-git-prep' sleep $SLEEP_TIME
        sleep $SLEEP_TIME
    done
    git checkout FETCH_HEAD
    git reset --hard FETCH_HEAD
    git clean -x -f -d -q
else
    git checkout $ZUUL_NEWREV
    git reset --hard $ZUUL_NEWREV
    git clean -x -f -d -q
fi
