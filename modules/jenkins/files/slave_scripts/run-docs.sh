#!/bin/bash -xe

# If a bundle file is present, call tox with the jenkins version of
# the test environment so it is used.  Otherwise, use the normal
# (non-bundle) test environment.  Also, run pip freeze on the
# resulting environment at the end so that we have a record of exactly
# what packages we ended up testing.
#

org=$1
project=$2

source /usr/local/jenkins/slave_scripts/functions.sh
check_variable_org_project "$org" "$project" "$0"

source /usr/local/jenkins/slave_scripts/select-mirror.sh $org $project

venv=venv

mkdir -p doc/build
export HUDSON_PUBLISH_DOCS=1
tox -e$venv -- python setup.py build_sphinx
result=$?

if [ -z "$ZUUL_REFNAME" ] || [ "$ZUUL_REFNAME" == "master" ] ; then
    : # Leave the docs where they are.
elif `echo $ZUUL_REFNAME | grep refs/tags/ >/dev/null` ; then
    # Put tagged releases in proper location. All tagged builds get copied to
    # BUILD_DIR/tagname. If this is the latest tagged release the copy of files
    # at BUILD_DIR remains. When Jenkins copies this file the root developer
    # docs are always the latest release with older tags available under the
    # root in the tagname dir.
    TAG=`echo $ZUUL_REFNAME | sed 's/refs.tags.//'`
    if [ ! -z $TAG ] ; then
        if echo $ZUUL_PROJECT | grep 'python-.*client' ; then
            # This is a hack to ignore the year.release tags in python-*client
            # projects.
            LATEST=`git tag | sed -n -e '/^2012\..*$/d' -e '/^\([0-9]\+\.\?\)\+$/p' | sort -V | tail -1`
        else
            # Take all tags of the form (number.)+, sort them, then take the
            # largest
            LATEST=`git tag | sed -n '/^\([0-9]\+\.\?\)\+$/p' | sort -V | tail -1`
        fi
        if [ "$TAG" = "$LATEST" ] ; then
            # Copy the docs into a subdir if this is a tagged build
            mkdir doc/build/$TAG
            cp -R doc/build/html/* doc/build/$TAG
            mv doc/build/$TAG doc/build/html/$TAG
        else
            # Move the docs into a subdir if this is a tagged build
            mkdir doc/build/$TAG
            mv doc/build/html/* doc/build/$TAG
            mv doc/build/$TAG doc/build/html/$TAG
        fi
    fi
elif `echo $ZUUL_REFNAME | grep stable/ >/dev/null` ; then
    # Put stable release changes in dir named after stable release under the
    # build dir. When Jenkins copies these files they will be accessible under
    # the developer docs root using the stable release's name.
    BRANCH=`echo $ZUUL_REFNAME | sed 's/stable.//'`
    if [ ! -z $BRANCH ] ; then
        # Move the docs into a subdir if this is a stable branch build
        mkdir doc/build/$BRANCH
        mv doc/build/html/* doc/build/$BRANCH
        mv doc/build/$BRANCH doc/build/html/$BRANCH
    fi
else
    # Put other branch changes in dir named after branch under the
    # build dir. When Jenkins copies these files they will be
    # accessible under the developer docs root using the branch name.
    # EG: feature/foo or milestone-proposed
    BRANCH=$ZUUL_REFNAME
    mkdir doc/build/tmp
    mv doc/build/html/* doc/build/tmp
    mkdir -p doc/build/html/$BRANCH
    mv doc/build/tmp/* doc/build/html/$BRANCH
fi

echo "Begin pip freeze output from test virtualenv:"
echo "======================================================================"
.tox/$venv/bin/pip freeze
echo "======================================================================"

exit $result
