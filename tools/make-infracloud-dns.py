#/usr/bin/env python3
#

import argparse
import ipaddress
import json

example = '''
"ironic-bm-test.bifrost.example": {
  "ansible_ssh_host": "1.1.1.1",
  "uuid": "11111111-1111-1111-1111-111111111111",
  "driver_info": {
    "power": {
      "ipmi_address": "10.0.0.1",
      "ipmi_username": "admin",
      "ipmi_password": "pass"
    },
  },
  "nics": [
    {
      "mac": "ff:ff:ff:ff:ff:ff"
    }
  ],
  "driver": "agent_ipmitool",
  "ipv4_address": "1.1.1.1",
  "properties": {
    "cpu_arch": "x86_64",
    "ram": null,
     "disk_size": null,
     "cpus": null
  },
  "name": "ironic-bm-test.bifrost.example"
}'''

parser = argparse.ArgumentParser()
parser.add_argument('inventory', help="Existing inventory json file")
parser.add_argument('--subnet', help="IPv4 subnet to add everything to",
                    required=True)
parser.add_argument('--domain', help="IPv4 subnet to add everything to")
parser.add_argument('--computes', help="How many computes", default=99)

args = parser.parse_args()

inventory = json.loads(open(args.inventory).read())

network = ipaddress.ip_network(args.subnet)

net_hosts = network.hosts()

dns_hosts = [('gateway', next(net_hosts))]
dns_hosts.append(('baremetal00', next(net_hosts)))
dns_hosts.append(('baremetal01', next(net_hosts)))
# XXX: assuming 2 controllers for now
dns_hosts.append(('controller00', next(net_hosts)))
dns_hosts.append(('controller01', next(net_hosts)))
# XXX: Reserve 2-digit tuples for not-compute
host = None
while True:
    host = next(net_hosts)
    if host.exploded[-3:] == '.99':
        break
if host is None:
    raise Exception('Cannot continue, subnet is too small')
for x in range(0, int(args.computes)):
    hostname = 'compute%03d' % x
    dns_hosts.append((hostname, next(net_hosts)))

# Now assign a box to each thing

new_inventory = {}
old_inventory = iter(inventory.items())

for host, ipv4 in dns_hosts:
    if host not in inventory:
        info = next(old_inventory)[1]
    else:
        info = inventory[host]
    if args.domain is not None:
        host = '{}.{}'.format(host, args.domain)
    info['name'] = host
    info['ipv4_address'] = ipv4.exploded
    new_inventory[host] = info

print(json.dumps(new_inventory, indent=2, sort_keys=True))
