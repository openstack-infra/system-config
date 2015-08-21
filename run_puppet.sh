#!/bin/bash

BASE_DIR=`pwd`

MODULE_DIR=${BASE_DIR}/modules
MODULE_PATH=${MODULE_DIR}:/etc/puppet/modules

/usr/bin/puppet apply --verbose --modulepath=$MODULE_PATH manifests/site.pp --certname=grafyaml.openstack.org
