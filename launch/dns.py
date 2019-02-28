#!/usr/bin/env python

# Launch a new OpenStack project infrastructure node.

# Copyright (C) 2013 OpenStack Foundation
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
#
# See the License for the specific language governing permissions and
# limitations under the License.

import argparse


def get_href(server):
    if not hasattr(server, 'links'):
        return None
    for link in server.links:
        if link['rel'] == 'self':
            return link['href']


def print_dns(cloud, server):
    ip4 = server.public_v4
    ip6 = server.public_v6

    if server.name.endswith('opendev.org'):
        print_dns_opendev(server.name.rsplit('.', 2)[0], ip4, ip6)
    else:
        print_dns_legacy(cloud, server, ip4, ip6)


def print_dns_opendev(name, ip4, ip6):

    print("\n")
    print("Put the following into zone-opendev.org:zones/opendev.org/zone.db")
    print("{name}			IN	A	{ip4}".format(name=name, ip4=ip4))
    if ip6:
        print("{name}			IN	AAAA	{ip6}".format(name=name, ip6=ip6))


def print_dns_legacy(cloud, server, ip4, ip6):
    # Get the server object from the sdk layer so that we can pull the
    # href data out of the links dict.
    try:
        raw_server = cloud.compute.get_server(server.id)
    except AttributeError:
        print("Please update your version of shade/openstacksdk."
              " openstacksdk >= 0.12 is required")
        raise
    href = get_href(raw_server)

    print("\n")
    print("Run the following commands to set up DNS:")
    print("\n")
    print(". ~root/ci-launch/openstackci-rs-nova.sh")
    print(". ~root/rackdns-venv/bin/activate")
    print("\n")
    print(
        "rackdns rdns-create --name %s \\\n"
        "    --data %s \\\n"
        "    --server-href %s \\\n"
        "    --ttl 3600" % (
            server.name, ip6, href))
    print("\n")
    print(
        "rackdns rdns-create --name %s \\\n"
        "    --data %s \\\n"
        "    --server-href %s \\\n"
        "    --ttl 3600" % (
            server.name, ip4, href))
    print("\n")
    print(". ~root/ci-launch/openstack-rs-nova.sh")
    print("\n")
    print(
        "rackdns record-create --name %s \\\n"
        "    --type AAAA --data %s \\\n"
        "    --ttl 3600 openstack.org" % (
            server.name, ip6))
    print("\n")
    print(
        "rackdns record-create --name %s \\\n"
        "    --type A --data %s \\\n"
        "    --ttl 3600 openstack.org" % (
            server.name, ip4))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("name", help="server name")
    options = parser.parse_args()

    import openstack
    cloud = openstack.connect()
    # Get the server using the shade layer so that we have server.public_v4
    # and server.public_v6
    try:
        server = cloud.get_server(options.name)
    except AttributeError:
        print("Please update your version of shade/openstacksdk."
              " openstacksdk >= 0.12 is required")
        raise
    print_dns(cloud, server)

if __name__ == '__main__':
    main()
