#!/bin/bash

# Copyright 2016 Hewlett Packard Enterprise Development Corporation, LP
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

set -e

CMD="/usr/bin/registry-static"
CMD_ARGS="-d <%= @uri_rewrite %> -o <%= @data_directory %> --blobstore afs-blob-store --hooks openstack-registry-hooks"

echo "Obtaining npm tokens and running registry-static."
k5start -t -f /etc/npm.keytab service/npm -- timeout -k 2m 30m $CMD $CMD_ARGS

echo "registry-static completed successfully, running vos release."
k5start -t -f /etc/afsadmin.keytab service/afsadmin -- vos release -v mirror.npm

echo "Done."
