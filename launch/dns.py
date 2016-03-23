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

    for raw_server in cloud.nova_client.servers.list():
        if raw_server.id == server.id:
            href = get_href(raw_server)

    print
    print "Run the following commands to set up DNS:"
    print
    print ". ~root/ci-launch/openstackci-rs-nova.sh"
    print ". ~root/rackdns-venv/bin/activate"
    print
    print (
        "rackdns rdns-create --name %s \\\n"
        "    --data %s \\\n"
        "    --server-href %s \\\n"
        "    --ttl 3600" % (
            server.name, ip6, href))
    print
    print (
        "rackdns rdns-create --name %s \\\n"
        "    --data %s \\\n"
        "    --server-href %s \\\n"
        "    --ttl 3600" % (
            server.name, ip4, href))
    print
    print ". ~root/ci-launch/openstack-rs-nova.sh"
    print
    print (
        "rackdns record-create --name %s \\\n"
        "    --type AAAA --data %s \\\n"
        "    --ttl 3600 openstack.org" % (
            server.name, ip6))
    print
    print (
        "rackdns record-create --name %s \\\n"
        "    --type A --data %s \\\n"
        "    --ttl 3600 openstack.org" % (
            server.name, ip4))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("name", help="server name")
    options = parser.parse_args()

    import shade
    cloud = shade.openstack_cloud()
    server = cloud.get_server(options.name)
    print_dns(cloud, server)

if __name__ == '__main__':
    main()
