#!/bin/bash

set -e

export OS_IMAGE_API_VERSION=2

qemu-img convert -O raw ubuntu.qcow2 ubuntu.raw
sudo docker run -v $(pwd):/images emonty/vhd-util convert -s 0 -t 1 -i /images/ubuntu.raw -o /images/intermediate.vhd
sudo docker run -v $(pwd):/images emonty/vhd-util convert -s 1 -t 2 -i /images/intermediate.vhd -o /images/ubuntu.vhd
swift upload --object-name test-monty-ubuntu.vhd images ubuntu.vhd
id=$(glance image-list | grep "Test Monty Ubuntu" | awk '{print $2}')
glance image-delete $id
glance task-create --type=import --input='{"import_from": "images/test-monty-ubuntu.vhd", "image_properties" : {"name": "Test Monty Ubuntu"}}'

echo "Please poll for the import task to complete"
