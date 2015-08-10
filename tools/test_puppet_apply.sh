#!/bin/bash -ux

# Copyright 2015 Hewlett-Packard Development Company, L.P.
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

file=$1
set +x
fileout=${file}.out
echo "##" > $fileout
cat $file > $fileout
sudo puppet apply --modulepath=${MODULE_PATH} --color=false --noop --verbose --debug $file >/dev/null 2>> $fileout
ret=$?
if [ $ret -ne 0 ]; then
    echo FAILURE
    echo =======
    cat $fileout
    echo =======
    echo Errors that are possibly responsible, most likely at the top
    echo =======
    cat $fileout | sed -r "s/\x1B\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]//g" | grep ^Error:
    echo =======
    exit $ret
fi
echo SUCCESS
