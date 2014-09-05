#!/bin/bash -xe

# Copyright (C) 2014 Hewlett-Packard Development Company, L.P.
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
#
# See the License for the specific language governing permissions and
# limitations under the License.

source /etc/nodepool/provider

cat >/home/jenkins/.pip/pip.conf <<EOF
[global]
index-url = http://pypi.$NODEPOOL_REGION.openstack.org/simple
EOF

cat >/home/jenkins/.pydistutils.cfg <<EOF
[easy_install]
index_url = http://pypi.$NODEPOOL_REGION.openstack.org/simple
EOF
