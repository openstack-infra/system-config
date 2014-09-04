#!/bin/bash

if ! test -z $1 ; then
    BASE_DIR=$1
else
    BASE_DIR=`pwd`
fi

MODULE_DIR=${BASE_DIR}/modules
MODULE_PATH=${MODULE_DIR}:/etc/puppet/modules
MANIFEST_LOG=/var/log/manifest.log

cd $BASE_DIR
/usr/bin/git pull -q && \
    /bin/bash install_modules.sh && \
    /usr/bin/puppet apply -l $MANIFEST_LOG --modulepath=$MODULE_PATH manifests/site.pp
