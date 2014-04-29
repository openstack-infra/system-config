#!/bin/bash -ex

# This file is a helper for versioning and deployment of
# maven projects.  It sets up environment variables to
# pass to maven build commands so that we can generate
# versioned builds within the gerrit workflow.

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

echo "SCM_SHA=$SCM_SHA" >maven.properties
echo "PROJECT_VER=$PROJECT_VER" >>maven.properties
echo "COMMITS_SINCE_TAG=$COMMITS_SINCE_TAG" >>maven.properties
