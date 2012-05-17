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

snapshotversion=$(find_next_version)

rm -f dist/*.tar.gz
if [ -f setup.py ] ; then
    # Try tox and cached bundles first
    if [ -e ".cache.bundle" ] ; then
        if [ -f tox.ini ] ; then
            if tox --showconfig | grep testenv | grep jenkinsvenv >/dev/null 2>&1
            then
                tox -ejenkinsvenv python setup.py sdist
            else
                tox -evenv python setup.py sdist
            fi
        else
            rm -rf .venv
            mv .cache.bundle .cache.pybundle
            virtualenv --no-site-packages .venv
            .venv/bin/pip install .cache.pybundle
            rm .cache.pybundle
            tools/with_venv.sh python setup.py sdist
        fi
    # Try old style venv's second
    elif [ -d .venv -a -f tools/with_venv.sh ] ; then
        tools/with_venv.sh python setup.py sdist
    # Last but not least, just make a tarball
    else
        python setup.py sdist
    fi
    # There should only be one, so this should be safe.
    tarball=$(echo dist/*.tar.gz)

    echo mv "$tarball" "dist/$(basename $tarball .tar.gz)${SEPARATOR}${snapshotversion}.tar.gz"
    mv "$tarball" "dist/$(basename $tarball .tar.gz)${SEPARATOR}${snapshotversion}.tar.gz"
fi
