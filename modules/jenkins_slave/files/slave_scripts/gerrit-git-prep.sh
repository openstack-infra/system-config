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

if [ -z "$GERRIT_NEWREV" ] && [ -z "$GERRIT_REFSPEC" ] && [ -z "$GERRIT_CHANGES" ]
then
    echo "This job may only be triggered by Gerrit."
    exit 1
fi

if [ ! -z "$GERRIT_CHANGES" ]
then
    CHANGE_NUMBER=`echo $GERRIT_CHANGES|grep -Po ".*/\K\d+(?=/\d+)"`
    echo "Triggered by: https://$SITE/$CHANGE_NUMBER"
fi

if [ ! -z "$GERRIT_REFSPEC" ]
then
    CHANGE_NUMBER=`echo $GERRIT_REFSPEC|grep -Po ".*/\K\d+(?=/\d+)"`
    echo "Triggered by: https://$SITE/$CHANGE_NUMBER"
fi

function merge_change {
    PROJECT=$1
    REFSPEC=$2
    MAX_ATTEMPTS=${3:-3}
    COUNT=0

    until git fetch https://$SITE/p/$PROJECT $REFSPEC
    do
        COUNT=$(($COUNT + 1))
        logger -p user.warning -t 'gerrit-git-prep' FAILED: git fetch https://$SITE/p/$PROJECT $REFSPEC COUNT: $COUNT
        if [ $COUNT -eq $MAX_ATTEMPTS ]
        then
            break
        fi
        SLEEP_TIME=$((30 + $RANDOM % 60))
        logger -p user.warning -t 'gerrit-git-prep' sleep $SLEEP_TIME
        sleep $SLEEP_TIME
    done

    if [ $COUNT -lt $MAX_ATTEMPTS ]
    then
        # This should be equivalent to what gerrit does if a repo is
        # set to "merge commits when necessary" and "automatically resolve
        # conflicts" is set to true:
        git merge -s resolve FETCH_HEAD
    else
        # Failed to fetch too many times. Notify jenkins of the failure.
        # This is necessary because set -e does not apply to the condition of
        # until.
        exit 1
    fi
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
