#!/bin/bash
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
# Upload java binaries to repo.jenkinsci.org with Curl.

PROJECT=$1
VERSION=$2

JENKINS_CI_URL=`http://repo.jenkins-ci.org/list/releases/org/jenkins-ci/plugins`
SOURCE_FILE_PATH=`./target`
FILE_EXTENSION=`hpi`
SOURCE_FILENAME=`${PROJECT}.${FILE_EXTENSION}`
DEST_FILENAME=`${PROJECT}-${VERSION}.${FILE_EXTENSION}`
MD5_DIGEST=`md5sum ${SOURCE_FILE_PATH}/${SOURCE_FILENAME | cut -d' ' -f1`


curl --config /home/jenkins/.jenkinsci-curl \
    -X PUT \
    --data-binary @${SOURCE_FILE_PATH}/${SOURCE_FILENAME} \
    -i "${JENKINS_CI_URL}/${PROJECT}/${VERSION}/${DEST_FILENAME}" /dev/null 2>&1

exit $?
