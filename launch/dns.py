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

import os
import argparse
import utils

import shade


def print_dns(client, name):
    for server in client.servers.list():
        if server.name != name:
            continue
        ip4 = utils.get_public_ip(server)
        ip6 = utils.get_public_ip(server, 6)
        href = utils.get_href(server)

        print
        print "Run the following commands to set up DNS:"
        print
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


def print_dns(name=None, cloud=None, server=None):

    if not server:
        server = cloud.get_server(name)

    ip4 = server.public_v4
    ip6 = server.public_v6
    href = utils.get_href(server)

    print
    print "Run the following commands to set up DNS:"
    print
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
    parser.add_argument("--cloud", dest="cloud",
                        help="cloud name", default='envvars')
    parser.add_argument("--region", dest="region",
                        help="cloud region")
    options = parser.parse_args()

    cloud = shade.openstack_cloud(
        cloud=options.cloud, region_name=options.region)

    print_dns(cloud=cloud, name=options.name)

if __name__ == '__main__':
    main()
