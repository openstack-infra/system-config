#!/usr/bin/env bash

export OS_AUTH_URL=http://192.168.69.1:5000/v2.0
export OS_TENANT_ID=bc4ef31e0f1c4412bddc0b7ac606d5f2
export OS_TENANT_NAME="opencontrail-ci"
export OS_USERNAME="anantha"
export OS_PASSWORD=anantha123 # $OS_PASSWORD_INPUT

CMD=$1
shift
$CMD $*

