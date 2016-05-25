#!/bin/bash -ex

# Copyright 2014 Hewlett-Packard Development Company, L.P.
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

ROOT=$(readlink -fn $(dirname $0)/..)
export MODULE_PATH="${ROOT}/modules:/etc/puppet/modules"
# MODULE_ENV_FILE sets the list of modules to read from and install and can be
# overridden by setting it outside the script.
export MODULE_ENV_FILE=${MODULE_ENV_FILE:-modules.env}
# PUPPET_MANIFEST sets the manifest that is being tested and can be overridden
# by setting it outside the script.
export PUPPET_MANIFEST=${PUPPET_MANIFEST:-manifests/site.pp}

export PUPPET_INTEGRATION_TEST=1

sudo rm -rf /etc/puppet/modules/*

cat > clonemap.yaml <<EOF
clonemap:
  - name: '(.*?)/puppet-(.*)'
    dest: '/etc/puppet/modules/\2'
EOF

# These arrays are initialized here and populated in modules.env

# Array of modules to be installed key:value is module:version.
declare -A MODULES

# Array of modues to be installed from source and without dependency resolution.
# key:value is source location, revision to checkout
declare -A SOURCE_MODULES

# Array of modues to be installed from source and without dependency resolution from openstack git
# key:value is source location, revision to checkout
declare -A INTEGRATION_MODULES


project_names=""

source $MODULE_ENV_FILE

for MOD in ${!INTEGRATION_MODULES[*]}; do
    project_scope=$(basename `dirname $MOD`)
    repo_name=`basename $MOD`
    project_names+=" $project_scope/$repo_name"
done

sudo -E /usr/zuul-env/bin/zuul-cloner -m clonemap.yaml --cache-dir /opt/git \
    git://git.openstack.org \
    $project_names

grep -v 127.0.1.1 /etc/hosts >/tmp/hosts
HOST=`echo $HOSTNAME |awk -F. '{ print $1 }'`
echo "127.0.1.1 $HOST.openstack.org $HOST" >> /tmp/hosts
sudo mv /tmp/hosts /etc/hosts

# Manage hiera
sudo mkdir -p /opt/system-config
sudo ln -s $(pwd) /opt/system-config/production
sudo cp modules/openstack_project/files/puppet/hiera.yaml /etc/hiera.yaml
sudo cp modules/openstack_project/files/puppet/hiera.yaml /etc/puppet/hiera.yaml

# Demonstrate that hiera lookups are functioning
find /opt/system-config/production/hiera
hiera -c /etc/puppet/hiera.yaml -d elasticsearch_nodes ::environment=production
