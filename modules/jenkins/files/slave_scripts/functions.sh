#
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
#
# helper functions

function check_variable_org_project()
{
    org=$1
    project=$2
    filename=$3

    if [[ -z "$org" || -z "$project" ]]
    then
        echo "Usage: $filename ORG PROJECT"
        echo
        echo "ORG: The project organization (eg 'openstack')"
        echo "PROJECT: The project name (eg 'nova')"
        exit 1
    fi
}

function check_variable_version_org_project()
{
    version=$1
    org=$2
    project=$3
    filename=$4
    if [[ -z "$version" || -z "$org" || -z "$project" ]]
    then
        echo "Usage: $filename VERSION ORG PROJECT"
        echo
        echo "VERSION: The tox environment python version (eg '27')"
        echo "ORG: The project organization (eg 'openstack')"
        echo "PROJECT: The project name (eg 'nova')"
        exit 1
    fi
}
