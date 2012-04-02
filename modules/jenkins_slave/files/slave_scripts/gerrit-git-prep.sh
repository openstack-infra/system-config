#!/bin/bash -xe

SITE=$1
if [ -z "$SITE" ]
then
  echo "The site name (eg 'openstack') must be the first argument."
  exit 1
fi

if [ -z "$GERRIT_NEWREV" ] && [ -z "$GERRIT_REFSPEC" ]
then
    echo "This job may only be triggered by Gerrit."
    exit 1
fi

if [[ ! -e .git ]]
then
    git clone https://review.$SITE.org/p/$GERRIT_PROJECT .
fi
git remote update || git remote update # attempt to work around bug #925790
git reset --hard
git clean -x -f -d -q

if [ ! -z "$GERRIT_REFSPEC" ]
then
    git checkout $GERRIT_BRANCH
    git reset --hard remotes/origin/$GERRIT_BRANCH
    git clean -x -f -d -q
    git fetch https://review.$SITE.org/p/$GERRIT_PROJECT $GERRIT_REFSPEC
    git merge FETCH_HEAD
else
    git checkout $GERRIT_NEWREV
    git reset --hard $GERRIT_NEWREV
    git clean -x -f -d -q
fi
