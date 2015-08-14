#!/bin/bash

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



for mod in $(ls /etc/puppet/modules/); do
    echo -n "${mod}: "
    cd /etc/puppet/modules/$mod
    branch=$(git rev-parse --abbrev-ref HEAD)
    if [[ $branch == "HEAD" ]]; then
        tag=$(git name-rev --name-only --tags $(git rev-parse HEAD))
        version=$tag
    else
        version=$branch
    fi
    echo $version
    cd - >/dev/null

done
