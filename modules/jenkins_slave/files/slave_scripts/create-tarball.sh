#!/bin/bash -xe

# In case we start doing something more sophisticated with other refs
# later (such as tags).
BRANCH=$GERRIT_REFNAME

if [ $BRANCH == "milestone-proposed" ]
then
    REVNOPREFIX="r"
fi
if [[ $BRANCH =~ ^stable/.*$ ]]
then
    NOMILESTONE="true"
fi

# Should be ~ if tarball version is the one we're working *toward*. (By far preferred!)
# Should be + if tarball version is already released and we're moving forward after it.
SEPARATOR=${SEPARATOR:-'~'}

if [ -z "$1" ]
then
    echo '$1 not set.'
    exit 1
fi
PROJECT=$1

find_next_version() {
    datestamp="${datestamp:-$(date +%Y%m%d)}"
    git fetch origin +refs/meta/*:refs/remotes/meta/*
    milestonever="$(git show meta/openstack/release:${BRANCH})"
    if [ $? != 0 ]
    then
        if [ "$NOMILESTONE" = "true" ]
        then
            milestonever=""
        else
            echo "Milestone file ${BRANCH} not found. Bailing out." >&2
            exit 1
        fi
    fi

    version="$milestonever"
    if [ -n "$version" ]
    then
        version="${version}~"
    fi
    revno="${revno:-$(git log --oneline |  wc -l)}"
    version="$(printf %s%s.%s%d "$version" "$datestamp" "$REVNOPREFIX" "$revno")"
    printf "%s" "$version"
}


rm -f dist/*.tar.gz
if [ -f setup.py ] ; then
    tox -evenv python setup.py sdist
    # There should only be one, so this should be safe.
    tarball=$(echo dist/*.tar.gz)
    # If our tarball includes a versioninfo file, use that version
    snapshotversion=`tar --wildcards -O -z -xf $tarball *versioninfo 2>/dev/null || true`
    if [ "x${snapshotversion}" = "x" ] ; then
        snapshotversion=$(find_next_version)
        echo mv "$tarball" "dist/$(basename $tarball .tar.gz)${SEPARATOR}${snapshotversion}.tar.gz"
        mv "$tarball" "dist/$(basename $tarball .tar.gz)${SEPARATOR}${snapshotversion}.tar.gz"
    elif [ "$tarball" != "dist/${PROJECT}-${snapshotversion}.tar.gz" ] ; then
        echo mv "$tarball" "dist/${PROJECT}-${snapshotversion}.tar.gz"
        mv "$tarball" "dist/${PROJECT}-${snapshotversion}.tar.gz"
    fi
fi
