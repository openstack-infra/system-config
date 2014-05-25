#!/bin/bash
# Copyright (c) 2014 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

export ELEMENTS_PATH=${ELEMENTS_PATH:-modules/openstack_project/files/nodepool/elements}
export DISTRO=${DISTRO:-ubuntu}
export DIB_RELEASE=${DIB_RELEASE:-precise}
export DIB_IMAGE_NAME=${DIB_IMAGE_NAME:-${DISTRO}_${DIB_RELEASE}}
export DIB_IMAGE_FILENAME=${DIB_IMAGE_FILENAME:-${DIB_IMAGE_NAME}.qcow}
export NODEPOOL_SCRIPTDIR=${NODEPOOL_SCRIPTDIR:-modules/openstack_project/files/nodepool/scripts}
export CONFIG_SOURCE=${CONFIG_SOURCE:-$(pwd)}
export CONFIG_REF=${CONFIG_REF:-$(git rev-parse HEAD)}

disk-image-create -x --no-tmpfs -o devstack-gate-$DIB_RELEASE $DISTRO vm openstack-repos puppet nodepool-base node-devstack
