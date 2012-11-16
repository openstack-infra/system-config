#!/bin/bash

PROJECT=$1

FILENAME=`ls ${PROJECT}*.tar.gz`
# Strip project name and extension leaving only the version.
VERSION=`echo ${FILENAME} | sed -n "s/${PROJECT}-\(.*\).tar.gz/\1/p"`
MD5_DIGEST=`openssl dgst -md5 ${FILENAME} | cut -d'=' -f2 | tr -d '[:space:]'`

# Explicitly disable tracing to avoid dumping the password.
set +x
source /home/jenkins/.pypiactivate
curl -u ${UNAME}:${PASSWD} \
     -F "content=@${FILENAME};filename=${FILENAME}" \
     -F ":action=file_upload" \
     -F "protocol_version=1" \
     -F "name=${PROJECT}" \
     -F "version=${VERSION}" \
     -F "file_type=sdist" \
     -F "md5_digest=${MD5_DIGEST}" > /dev/null 2>&1

exit $?
