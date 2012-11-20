#!/bin/bash
#
# Copyright 2012  Hewlett-Packard Development Company, L.P.
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
# Upload python sdist to pypi with Curl.

PROJECT=$1

FILENAME=`ls ${PROJECT}*.tar.gz`
# Strip project name and extension leaving only the version.
VERSION=`echo ${FILENAME} | sed -n "s/${PROJECT}-\(.*\).tar.gz/\1/p"`
MD5_DIGEST=`md5sum ${FILENAME} | cut -d' ' -f1`

/usr/local/jenkins/slave_scripts/pypi-extract-metadata.py $FILENAME metadata.curl

curl --config /home/jenkins/.pypicurl \
     --config metadata.curl \
     -F "filetype=sdist" \
     -F "content=@${FILENAME};filename=${FILENAME}" \
     -F ":action=file_upload" \
     -F "protocol_version=1" \
     -F "name=${PROJECT}" \
     -F "version=${VERSION}" \
     -F "md5_digest=${MD5_DIGEST}" \
     http://pypi.python.org/pypi > /dev/null 2>&1

exit $?
