#!/bin/bash

PROJECT=$1

FILENAME=`ls ${PROJECT}*.tar.gz`
# Strip project name and extension leaving only the version.
VERSION=`echo ${FILENAME} | sed -n "s/${PROJECT}-\(.*\).tar.gz/\1/p"`
MD5_DIGEST=`md5sum ${FILENAME} | cut -d' ' -f1`

curl --config /home/jenkins/.pypicurl \
     -F "content=@${FILENAME};filename=${FILENAME}" \
     -F ":action=file_upload" \
     -F "protocol_version=1" \
     -F "name=${PROJECT}" \
     -F "version=${VERSION}" \
     -F "file_type=sdist" \
     -F "md5_digest=${MD5_DIGEST}" \
     http://pypi.python.org/pypi > /dev/null 2>&1

exit $?
