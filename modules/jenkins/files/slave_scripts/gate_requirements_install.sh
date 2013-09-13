#!/bin/bash -xe

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

source /usr/local/jenkins/slave_scripts/select-mirror.sh openstack requirements
virtualenv --clear .venv
PIP_ARGS=""
REQ_FILES="tools/pip-requires tools/test-requires global-requirements.txt requirements.txt test-requirements.txt"
for FILE in $REQ_FILES
do
  if [ -e $FILE ]
  then
    # Ignore lines beginning with https?:// just as the mirror script does.
    sed -e '/^https\?:\/\//d' $FILE > $FILE.clean
    PIP_ARGS="$PIP_ARGS -r $FILE.clean"
  fi
done
# Run the same basic pip command that the mirror script runs.
.venv/bin/pip install -M -U --exists-action=w $PIP_ARGS
if [ -e dev-requirements.txt ] ; then
    .venv/bin/pip install -M -U --exists-action=w -r dev-requirements.txt
fi

# Print all installed stuff to demonstrate versions
.venv/bin/pip freeze
