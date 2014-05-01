#!/bin/bash -xe

# Copyright (C) 2014 Hewlett-Packard Development Company, L.P.
#    All Rights Reserved.
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

HOSTNAME=$1
SUDO='true'
THIN='false'
PYTHON3='false'
PYPY='false'
ALL_MYSQL_PRIVS='true'
GIT_PROTOCOL=http
ENABLE_UNBOUND=false

export http_proxy=$NODEPOOL_HTTP_PROXY
export https_proxy=$NODEPOOL_HTTPS_PROXY
export no_proxy=$NODEPOOL_NO_PROXY

sudo bash -xe sudo_keep_proxy_settings.sh
sudo bash -xe sudo_install_proxy_settings.sh

./prepare_node.sh "$HOSTNAME" "$SUDO" "$THIN" "$PYTHON3" "$PYPY" "$ALL_MYSQL_PRIVS" "$GIT_PROTOCOL" "$ENABLE_UNBOUND"

./restrict_memory.sh
