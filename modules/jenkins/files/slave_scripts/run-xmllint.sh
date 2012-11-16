#!/bin/bash -xe

mkdir -p openstack-compute-api-2/target/2/wadl/

/usr/bin/xmllint -noent openstack-compute-api-2/src/os-compute-2.wadl \
    openstack-compute-api-2/target/2/wadl/os-compute-2.wadl
