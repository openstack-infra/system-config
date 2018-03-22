#!/bin/bash

# Copyright 2017 Red Hat, Inc.
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

PROJECTS_YAML=${PROJECTS_YAML:-/etc/project-config/gerrit/projects.yaml}
REINDEX_LOCK=/var/www/hound/reindex.lock

TEMP_DIR=$(mktemp -d)
trap "rm -rf ${TEMP_DIR} EXIT"

pushd ${TEMP_DIR}

echo $(date)
echo "Starting hound config update"

# Generate the new config
PROJECTS_YAML=${PROJECTS_YAML} create-hound-config

# See if we need to update
NEW="$(md5sum config.json | awk '{print $1}')"
OLD="$(md5sum /home/hound/config.json  | awk '{print $1}')"
if [[ ${NEW} == ${OLD} ]]; then
    echo "Nothing to do"
    exit 0
fi

echo "Recreating config"

# Move the new config into place
chown hound:hound config.json
chmod 0644 config.json
cp /home/hound/config.json /home/hound/config.json.bak
mv ./config.json /home/hound/config.json

# release the hounds
touch ${REINDEX_LOCK}
service hound stop
sleep 2
service hound start

# Hound takes a few minutes to go through all our projects.  We know
# it's ready when we see it listening on port 6080
echo "Waiting for hound..."
while ! netstat -lnt | grep -q ':6080.*LISTEN\s*$' ; do
    echo "  ... still waiting"
    sleep 5
done

rm ${REINDEX_LOCK}

echo "... done"

