#!/bin/sh

# Copyright 2018 Red Hat, Inc.
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

# Create directories needed by gitea
mkdir -p /data/git
chown 1000:1000 /data/git

mkdir -p /data/gitea
chown 1000:1000 /data/gitea

mkdir -p /data/gitea/ssl
chown 1000:1000 /data/gitea/ssl
chmod 0500 /data/gitea/ssl
cp /secrets/gitea_tls_cert /data/gitea/ssl/cert.pem
cp /secrets/gitea_tls_key /data/gitea/ssl/key.pem

# This one is used by openssh and can remain root-owned
mkdir -p /data/ssh

# Template the config file (which can also be root-owned)
export JINJA_SRC_FILE=/config_src/app.ini.j2
export JINJA_DEST_FILE=/conf/app.ini
python /run.py
