#!/bin/bash -x
#
# Copyright 2013  Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Upload java packages to maven repositories

PROJECT=$1
VERSION=$2
META_DATA_FILE=$3
PLUGIN_FILE=$4

# Strip project name and extension leaving only the version.
VERSION=`echo ${PLUGIN_FILE} | sed -n "s/${PROJECT}-\(.*\).jar/\1/p"`

# generate pom file with version info
POM_IN_ZIP=`unzip -Z -1 ${PLUGIN_FILE}|grep pom.xml`
unzip -o -j ${PLUGIN_FILE} ${POM_IN_ZIP}
sed "s/\${{project-version}}/${VERSION}/g" <pom.xml >${META_DATA_FILE}

# deploy plugin artifacts from workspace to maven central repository
MAVEN_REPO="https://oss.sonatype.org/content/groups/public/maven"
MAVEN_REPO_CREDS="~jenkins/.mavencentral-curl"

curl -X PUT \
    --config ${MAVEN_REPO_CREDS} \
    --data-binary @${META_DATA_FILE} \
    -i "${MAVEN_REPO}/${PROJECT}/${VERSION}/${META_DATA_FILE}" > /dev/null 2>&1

curl -X PUT \
    --config ${MAVEN_REPO_CREDS} \
    --data-binary @${PLUGIN_FILE} \
    -i "${MAVEN_REPO}/${PROJECT}/${VERSION}/${PLUGIN_FILE}" > /dev/null 2>&1
