#!/bin/bash -ex

# This is a script that helps us version build artifacts.  It retrieves
# git info and generates version strings.

# get version info from scm
SCM_TAG=`git describe --abbrev=0 --tags` || true
SCM_SHA=`git rev-parse --short HEAD` || true

# assumes format is like this  '0.0.4-2-g135721c'
COMMITS_SINCE_TAG=`git describe | awk '{split($0,a,"-"); print a[2]}'` || true

# just use git sha if there is no tag yet.
if [[ "${SCM_TAG}" == "" ]]; then
    SCM_TAG=$SCM_SHA
fi

# General build version should be something like '0.0.4.3.d4ee90c'
# Release build version should be something like '0.0.5'
if [[ "${COMMITS_SINCE_TAG}" == "" ]]; then
    PROJECT_VER=$SCM_TAG
else
    PROJECT_VER="$SCM_TAG.$COMMITS_SINCE_TAG.$SCM_SHA";
fi

echo "SCM_SHA=$SCM_SHA" >version.properties
echo "PROJECT_VER=$PROJECT_VER" >>version.properties
echo "COMMITS_SINCE_TAG=$COMMITS_SINCE_TAG" >>version.properties
