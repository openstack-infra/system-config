#!/bin/bash -xe

# In case we start doing something more sophisticated with other refs
# later (such as tags).
BRANCH=$ZUUL_REF
BRANCH_PATH=`echo $BRANCH | tr / -`
META_URL="https://review.openstack.org/p"

if [ $BRANCH == "milestone-proposed" ]
then
    REVNOPREFIX="r"
fi

if [ -z "$1" ]
then
    echo '$1 not set.'
    exit 1
fi
PROJECT=$1

find_next_version() {
    datestamp="${datestamp:-$(date +%Y%m%d)}"
    if [[ $BRANCH =~ ^stable/.*$ ]]
    then
        milestonever=""
    else
        milestonever="$(git show meta/openstack/release:${BRANCH})"
        if [ $? != 0 ]
        then
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


git fetch $META_URL/$ZUUL_PROJECT +refs/meta/*:refs/remotes/meta/*
rm -f dist/*.tar.gz
if [ -f setup.py ] ; then
    tox -evenv python setup.py sdist
    # There should only be one, so this should be safe.
    tarball=$(echo dist/*.tar.gz)
    # If our tarball includes a versioninfo file, use that version
    snapshotversion=`tar --wildcards -O -z -xf $tarball *versioninfo 2>/dev/null || true`
    if [ "x${snapshotversion}" = "x" ] ; then
        snapshotversion=$(find_next_version)
        echo mv "$tarball" "dist/$(basename $tarball .tar.gz)~${snapshotversion}.tar.gz"
        mv "$tarball" "dist/$(basename $tarball .tar.gz)~${snapshotversion}.tar.gz"
        cp "dist/$(basename $tarball .tar.gz)~${snapshotversion}.tar.gz" "dist/${PROJECT}-${BRANCH_PATH}.tar.gz"
    elif [ "$tarball" != "dist/${PROJECT}-${snapshotversion}.tar.gz" ] ; then
        echo mv "$tarball" "dist/${PROJECT}-${snapshotversion}.tar.gz"
        mv "$tarball" "dist/${PROJECT}-${snapshotversion}.tar.gz"
        cp "dist/${PROJECT}-${snapshotversion}.tar.gz" "dist/${PROJECT}-${BRANCH_PATH}.tar.gz"
    fi
fi
