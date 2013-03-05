#!/bin/bash -x

# Copyright 2013 OpenStack Foundation
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

org=$1
project=$2

if [[ -z "$org" || -z "$project" ]]
then
  echo "Usage: $0 ORG PROJECT"
  echo
  echo "ORG: The project organization (eg 'openstack')"
  echo "PROJECT: The project name (eg 'nova')"
  exit 1
fi

rm -f ~/.pydistutils.cfg
mkdir -p ~/.pip
rm -f ~/.pip/pip.conf

# For OpenStack projects, use the pypi.openstack.org mirror exclusively
if [ "$org" == "openstack" ]
then
echo $org
    cat <<EOF > ~/.pydistutils.cfg
[easy_install]
index_url = http://pypi.openstack.org
EOF
    cat <<EOF > ~/.pip/pip.conf
[global]
index-url = http://pypi.openstack.org
EOF
else
    cat <<EOF > ~/.pip/pip.conf
[global]
index-url = http://pypi.openstack.org
extra-index-url = http://pypi.python.org/simple
EOF
fi
