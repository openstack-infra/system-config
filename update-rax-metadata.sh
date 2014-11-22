#!/bin/bash

set -e

export OS_IMAGE_API_VERSION=2

id=$(glance image-list | grep "Test Monty Ubuntu" | awk '{print $2}')
glance image-update --property vm_mode=hvm --property xenapi_use_agent=true $id
