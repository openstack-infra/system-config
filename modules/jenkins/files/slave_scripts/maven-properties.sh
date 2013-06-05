#!/bin/bash -ex

# This file is a helper for building jenkins plugins.
# It sets up environment variables to pass to maven build commands
# so that we can generate versioned builds with out gerrit build
# and release workflow.

# get version info from scm
SCM_TAG=$(git describe --abbrev=0 --tags) || true
SCM_SHA=$(git rev-parse --short HEAD)

# just use git sha if there is no tag yet.
if [[ "${SCM_TAG}" == "" ]]; then
    SCM_TAG=$SCM_SHA
fi

# assumes format is like this  '0.0.4-2-g135721c'
COMMITS_SINCE_TAG=`git describe | awk '{split($0,a,"-"); print a[2]}'`
SCM_REVISION="$SCM_TAG.$SCM_SHA"

# for general builds, we want GENERAL_BUILD_VER to be like 0.0.4.3.d4ee90c
general() {
    if [[ "${COMMITS_SINCE_TAG}" == "" ]]; then
        GENERAL_BUILD_VER=$SCM_TAG
    else
        GENERAL_BUILD_VER="$SCM_TAG.$COMMITS_SINCE_TAG.$SCM_SHA";
    fi
}

echo "SCM_SHA=$SCM_SHA" >maven.properties
echo "COMMITS_SINCE_TAG=$COMMITS_SINCE_TAG" >maven.properties
echo "SCM_REVISION=$SCM_REVISION" >maven.properties
echo "GENERAL_BUILD_VER=$GENERAL_BUILD_VER" >maven.properties
