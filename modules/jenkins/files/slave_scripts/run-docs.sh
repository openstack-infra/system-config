#!/bin/bash -xe

# If a bundle file is present, call tox with the jenkins version of
# the test environment so it is used.  Otherwise, use the normal
# (non-bundle) test environment.  Also, run pip freeze on the
# resulting environment at the end so that we have a record of exactly
# what packages we ended up testing.
#

venv=venv

mkdir -p doc/build
export HUDSON_PUBLISH_DOCS=1
tox -e$venv -- python setup.py build_sphinx
result=$?
if `echo $GERRIT_REFNAME | grep refs/tags/ >/dev/null` ; then
    # Put tagged releases in proper location. All tagged builds get copied to
    # BUILD_DIR/tagname. If this is the latest tagged release the copy of files
    # at BUILD_DIR remains. When Jenkins copies this file the root developer
    # docs are always the latest release with older tags available under the
    # root in the tagname dir.
    TAG=`echo $GERRIT_REFNAME | sed 's/refs.tags.//'`
    if [ ! -z $TAG ] ; then
        LATEST=`git tag | sed -n '/^\([0-9]\+\.\?\)\+$/p' | sort -n | tail -1`
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
elif `echo $GERRIT_REFNAME | grep stable/ >/dev/null` ; then
    # Put stable release changes in dir named after stable release under the
    # build dir. When Jenkins copies these files they will be accessible under
    # the developer docs root using the stable release's name.
    BRANCH=`echo $GERRIT_REFNAME | sed 's/stable.//'`
    if [ ! -z $BRANCH ] ; then
        # Move the docs into a subdir if this is a stable branch build
        mkdir doc/build/$BRANCH
        mv doc/build/html/* doc/build/$BRANCH
        mv doc/build/$BRANCH doc/build/html/$BRANCH
    fi
fi

echo "Begin pip freeze output from test virtualenv:"
echo "======================================================================"
.tox/$venv/bin/pip freeze
echo "======================================================================"

exit $result
