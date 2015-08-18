#!/usr/bin/env python3
import argparse
import json
import yaml

parser = argparse.ArgumentParser()
parser.add_argument('inventory', help="Path to inventory json file")
parser.add_argument('hiera_path', help="Output hiera yaml here")
args = parser.parse_args()

inventory = json.loads(open(args.inventory).read())
new_inventory = dict(inventory)

hiera = {}

for name, info in inventory.items():
    password = info['driver_info']['power']['ipmi_password']
    key = name.replace('.', '_')
    key = name.replace('-', '_')
    key = '%s_ipmi_password' % key
    hiera[key] = password
    info = dict(info)
    info['driver_info']['power']['ipmi_password'] = '<%%= @%s %%>' % key
    new_inventory[name] = info

print(json.dumps(new_inventory, indent=2))
with open(args.hiera_path, 'w') as hiera_file:
    yaml.safe_dump(hiera, hiera_file)
