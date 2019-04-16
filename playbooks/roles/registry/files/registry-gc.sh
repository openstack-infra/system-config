#!/bin/bash

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

registry_url="http://localhost:5000"
registry_user="zuul"
registry_password="testpass"
cutoff=$(python3 -c "import datetime; print((datetime.datetime.utcnow()-datetime.timedelta(days=1)).strftime('%Y-%m-%dT%H:%M:%fZ'))")

prune_tag () {
    local tag_name="$1"
    echo "  Prune tag $tag_name"

    # Get manifest
    local manifest_out=$(curl -i -s -u $registry_user:$registry_password "$registry_url/v2/$repo_name/manifests/$tag_name" --header "Accept: application/vnd.docker.distribution.manifest.v2+json")
    local manifest=$(echo "$manifest_out" | awk '/^\r$/ {s=1} s')
    local manifest_digest=$(echo "$manifest_out" | awk '/Docker-Content-Digest:/{print substr($2, 1, length($2)-1)}')

    # Get image config
    local config_digest=$(echo "$manifest" | jq -rc '.config.digest')
    local image_config=$(curl -s -u $registry_user:$registry_password "$registry_url/v2/$repo_name/blobs/$config_digest")
    local image_created=$(echo "$image_config" | jq -rc '.created')

    if [[ ! "$image_created" > "$cutoff" ]]; then
	echo "  Delete tag"
	curl -X DELETE -s -u $registry_user:$registry_password "$registry_url/v2/$repo_name/manifests/$manifest_digest"
    fi
}

prune_repository () {
    local repo_name="$1"

    echo "Prune repository $repo_name"
    local taglist=$(curl -s -u $registry_user:$registry_password "$registry_url/v2/$repo_name/tags/list")

    for x in $(echo "$taglist" | jq -rc '.tags[]'); do
	prune_tag "$x"
    done
}

prune_registry () {
    local catalog=$(curl -s -u $registry_user:$registry_password "$registry_url/v2/_catalog")

    for x in $(echo "$catalog" | jq -rc '.repositories[]'); do
	prune_repository "$x"
    done
}

prune_registry
cd /etc/registry-docker
docker-compose down
/usr/bin/docker exec registrydocker_registry_1 registry garbage-collect /etc/docker/registry/config.yml
docker-compose up -d
