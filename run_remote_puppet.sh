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

function run_ssh {
    ssh root@$1 timeout 60m puppet agent --test
    ret=$?
    # Did we timeout
    if [ $ret eq 124 ]; the
        echo "TODO: Actually report this error"
    fi
    return $ret
}

FULL_LIST=$(puppet cert list -a  | grep '^\+' | awk '{print $2}' | sed 's/"//g')
OVERRIDE_LIST="
  git01.openstack.org
  git02.openstack.org
  git03.openstack.org
  git04.openstack.org
  git05.openstack.org
  review.openstack.org
"

cd /opt/config/production

# Run things that need to be ordered
for host in $OVERRIDE_LIST; do
    run_ssh $host
done

# Now, run everyone else
for host in $FULL_LIST; do
    if ! echo $OVERRIDE_LIST | grep $host >/dev/null 2>&1 ; then
        run_ssh $host
    fi
done
