#!/usr/bin/env python3
import argparse
import json
import os

import yaml

parser = argparse.ArgumentParser()
parser.add_argument('inventory', help="Path to inventory json file")
parser.add_argument('hiera_path', help="Output hiera yaml here")
args = parser.parse_args()

inventory = json.loads(open(args.inventory).read())
new_inventory = dict(inventory)
hiera = {'ipmi_passwords': {}}
if os.path.exists(args.hiera_path):
    with open(args.hiera_path, 'r') as hiera_file:
        hiera = yaml.safe_load(hiera_file.read())

for name, info in inventory.items():
    password = info['driver_info']['power']['ipmi_password']
    address = info['driver_info']['power']['ipmi_address']
    if address not in hiera['ipmi_passwords']:
        hiera['ipmi_passwords'][address] = password
    info = dict(info)
    template = "<%= ipmi_passwords['{}'] %>".format(address)
    info['driver_info']['power']['ipmi_password'] = template
    new_inventory[name] = info

print(json.dumps(new_inventory, indent=2, sort_keys=True))
with open(args.hiera_path, 'w') as hiera_file:
    yaml.safe_dump(hiera, hiera_file)
