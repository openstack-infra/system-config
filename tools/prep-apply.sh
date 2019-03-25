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
# MODULE_ENV_FILE sets the list of modules to read from and install and can be
# overridden by setting it outside the script.
export MODULE_ENV_FILE=${MODULE_ENV_FILE:-modules.env}
# PUPPET_MANIFEST sets the manifest that is being tested and can be overridden
# by setting it outside the script.
export PUPPET_MANIFEST=${PUPPET_MANIFEST:-manifests/site.pp}
export PUPPET_VERSION=${PUPPET_VERSION:-3}

export PUPPET_INTEGRATION_TEST=1

# These arrays are initialized here and populated in modules.env

# Array of modules to be installed key:value is module:version.
declare -A MODULES

# Array of modues to be installed from source and without dependency resolution.
# key:value is source location, revision to checkout
declare -A SOURCE_MODULES

# Array of modues to be installed from source and without dependency resolution from openstack git
# key:value is source location, revision to checkout
declare -A INTEGRATION_MODULES

source $MODULE_ENV_FILE

# Install puppet
SETUP_PIP=false sudo -E bash -x $ROOT/install_puppet.sh
if [ "$PUPPET_VERSION" == "3" ] ; then
    export MODULE_PATH=/etc/puppet/modules
elif [ "$PUPPET_VERSION" == "4" ] ; then
    export MODULE_PATH=/etc/puppetlabs/code/modules
else
    echo "ERROR: unsupported puppet version $PUPPET_VERSION"
    exit 1
fi
# Remove previously-installed modules
sudo rm -rf $MODULE_PATH/*
# Install SOURCE_MODULES
sudo -E bash -x $ROOT/install_modules.sh

# Install INTEGRATION_MODULES
cat > clonemap.yaml <<EOF
clonemap:
  - name: '(.*?)/puppet-(.*)'
    dest: '$MODULE_PATH/\2'
  - name: '(.*?)/ansible-role-(.*)'
    dest: '/etc/ansible/roles/\2'
EOF

project_names="openstack-infra/ansible-role-puppet"

for MOD in ${!INTEGRATION_MODULES[*]}; do
    project_scope=$(basename `dirname $MOD`)
    repo_name=`basename $MOD`
    project_names+=" $project_scope/$repo_name"
done

sudo -E /usr/zuul-env/bin/zuul-cloner -m clonemap.yaml --cache-dir /opt/git \
    https://git.openstack.org \
    $project_names

# Fix hostname lookups
grep -v 127.0.1.1 /etc/hosts >/tmp/hosts
HOST=`echo $HOSTNAME |awk -F. '{ print $1 }'`
echo "127.0.1.1 $HOST.openstack.org $HOST" >> /tmp/hosts
sudo mv /tmp/hosts /etc/hosts

# Set up the production config directory, and then let ansible take care
# of configuring hiera.
sudo mkdir -p /opt/system-config
sudo ln -sf $(pwd) /opt/system-config/production
# Really make sure that the openstack_project module is in the module path
sudo ln -sf /opt/system-config/production/modules/openstack_project $MODULE_PATH
sudo -H mkdir -p ~/.ansible/tmp

virtualenv --system-site-packages /tmp/apply-ansible-env
/tmp/apply-ansible-env/bin/pip install ansible
