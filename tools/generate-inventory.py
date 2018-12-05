#!/usr/bin/env python3
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

#
# This script generates a static inventory YAML file suitable for
# ansible by querying the providers using the dynamic inventory
# generator.  Previously we had ansible dynamically generate it's
# inventory using it's openstack inventory generator plugin on each
# run, but it was found to be somewhat unreliable if a single
# cloud-provider became unavailable -- it would halt the whole ansible
# run.
#

import argparse
import logging
import yaml
import openstack
import os
import sys

from openstack.cloud import inventory

parser = argparse.ArgumentParser(
    description='Generate a static inventory via a query of cloud providers')

parser.add_argument("--debug", help="enable some debugging output",
                    action="store_true")
parser.add_argument("--output", help="output to file", default='openstack.yaml')
parser.add_argument("--force", help="overwrite output file if exists",
                    action="store_true")

args = parser.parse_args()

logging.basicConfig(level=logging.DEBUG if args.debug else logging.INFO)
if args.debug:
    openstack.enable_logging(debug=True)

if os.path.exists(args.output) and not args.force:
    logging.error("Refusing to overwrite output: %s" % args.output)
    sys.exit(1)

filtered_inv = {}
logging.info("Querying inventory ...")
inv = inventory.OpenStackInventory()
for host in inv.list_hosts(expand=False):
    logging.info("Found %s" % host['name'])
    filtered_inv[host['name']] = dict(
        ansible_host=host['interface_ip'],
        public_v4=host['public_v4'],
        private_v4=host['private_v4'],
        public_v6=host['public_v6'],
        )
full = dict(all=dict(hosts=filtered_inv))
logging.info("Writing output to: %s" % args.output)
# note default_flow_style=False keeps everything in
# block style, which is much more ansible-y
yaml.dump(full, open(args.output, 'w'),
          default_flow_style=False)
logging.info("Done!")
