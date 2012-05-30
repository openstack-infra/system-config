#!/bin/bash -e

# Needed environment variables:
# GERRIT_PROJECT
# GERRIT_BRANCH
# GERRIT_REFSPEC or GERRIT_NEWREV or GERRIT_CHANGES
#
# GERRIT_CHANGES format:
# GERRIT_CHANGES="gtest-org/test:master:refs/changes/20/420/1^gtest-org/test:master:refs/changes/21/421/1"
# GERRIT_CHANGES="gtest-org/test:master:refs/changes/21/421/1"
# GERRIT_CHANGES=""

SITE=$1
if [ -z "$SITE" ]
then
  echo "The site name (eg 'review.openstack.org') must be the first argument."
  exit 1
fi

if [ -z "$GERRIT_NEWREV" ] && [ -z "$GERRIT_REFSPEC" ] && [ -z "$GERRIT_CHANGES"]
then
    echo "This job may only be triggered by Gerrit."
    exit 1
fi

function merge_change {
    PROJECT=$1
    REFSPEC=$2
    
    git fetch https://$SITE/p/$PROJECT $REFSPEC
    git merge FETCH_HEAD
}

function merge_changes {
    set +x
    OIFS=$IFS
    IFS='^'
    for change in $GERRIT_CHANGES
    do
	OIFS2=$IFS
	IFS=':'
	change_array=($change)
	IFS=$OIFS2
   
	CHANGE_PROJECT=${change_array[0]}
	CHANGE_BRANCH=${change_array[1]}
	CHANGE_REFSPEC=${change_array[2]}

	if [ "$CHANGE_PROJECT" = "$GERRIT_PROJECT" ] &&
	   [ "$CHANGE_BRANCH" = "$GERRIT_BRANCH" ]; then
	    set -x
	    merge_change $CHANGE_PROJECT $CHANGE_REFSPEC
	    set +x
	fi
    done
    IFS=$OIFS
    set -x
}

set -x
if [[ ! -e .git ]]
then
    git clone https://$SITE/p/$GERRIT_PROJECT .
fi
git remote update || git remote update # attempt to work around bug #925790
git reset --hard
git clean -x -f -d -q

if [ -z "$GERRIT_NEWREV" ]
then
    git checkout $GERRIT_BRANCH
    git reset --hard remotes/origin/$GERRIT_BRANCH
    git clean -x -f -d -q

    if [ ! -z "$GERRIT_REFSPEC" ]    
    then
        merge_change $GERRIT_PROJECT $GERRIT_REFSPEC
    else
        merge_changes
    fi
else
    git checkout $GERRIT_NEWREV
    git reset --hard $GERRIT_NEWREV
    git clean -x -f -d -q
fi
