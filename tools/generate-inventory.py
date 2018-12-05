# Copyright (c) 2018 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import yaml

from openstack.cloud import inventory

filtered_inv = {}
inv = inventory.OpenStackInventory()
for host in inv.list_hosts(expand=False):
    filtered_inv[host['name']] = dict(
        ansible_host=host['interface_ip'],
        public_v4=host['public_v4'],
        private_v4=host['private_v4'],
        public_v6=host['public_v6'],
        )
full = dict(all=dict(hosts=filtered_inv))
yaml.dump(full, open('inventory/openstack.yaml', 'w'))
