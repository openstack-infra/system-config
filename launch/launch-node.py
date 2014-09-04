#!/usr/bin/env python

# Launch a new OpenStack project infrastructure node.

# Copyright (C) 2011-2012 OpenStack LLC.
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

import pwd
import sys
import os
import time
import traceback
import argparse

import dns
import utils

NOVA_USERNAME = os.environ['OS_USERNAME']
NOVA_PASSWORD = os.environ['OS_PASSWORD']
NOVA_URL = os.environ['OS_AUTH_URL']
NOVA_PROJECT_ID = os.environ['OS_TENANT_NAME']
NOVA_REGION_NAME = os.environ['OS_REGION_NAME']
NOVACLIENT_INSECURE = os.getenv('NOVACLIENT_INSECURE', None)
IPV6 = os.environ.get('IPV6', '0') is 1

SCRIPT_DIR = os.path.dirname(sys.argv[0])


def get_client():
    args = [NOVA_USERNAME, NOVA_PASSWORD, NOVA_PROJECT_ID, NOVA_URL]
    kwargs = {}
    kwargs['region_name'] = NOVA_REGION_NAME
    kwargs['service_type'] = 'compute'

    if NOVACLIENT_INSECURE:
        kwargs['insecure'] = True

    from novaclient.v1_1.client import Client
    client = Client(*args, **kwargs)
    return client


def bootstrap_server(
        server, admin_pass, key, cert, environment, name, puppetmaster, volume):
    ip = utils.get_public_ip(server)
    if not ip:
        raise Exception("Unable to find public ip of server")

    ssh_kwargs = {}
    if key:
        ssh_kwargs['pkey'] = key
    else:
        ssh_kwargs['password'] = admin_pass

    for username in ['root', 'ubuntu']:
        ssh_client = utils.ssh_connect(ip, username, ssh_kwargs, timeout=600)
        if ssh_client:
            break

    if not ssh_client:
        raise Exception("Unable to log in via SSH")

    if username != 'root':
        ssh_client.ssh("sudo cp ~/.ssh/authorized_keys"
                       " ~root/.ssh/authorized_keys")
        ssh_client.ssh("sudo chmod 644 ~root/.ssh/authorized_keys")
        ssh_client.ssh("sudo chown root.root ~root/.ssh/authorized_keys")

    ssh_client = utils.ssh_connect(ip, 'root', ssh_kwargs, timeout=600)

    if IPV6:
        ssh_client.ssh('ping6 -c5 -Q 0x10 review.openstack.org '
                       '|| ping6 -c5 -Q 0x10 wiki.openstack.org')

    ssh_client.scp(os.path.join(SCRIPT_DIR, '..', 'make_swap.sh'),
                   'make_swap.sh')
    ssh_client.ssh('bash -x make_swap.sh')

    if volume:
        ssh_client.scp(os.path.join(SCRIPT_DIR, '..', 'mount_volume.sh'),
                       'mount_volume.sh')
        ssh_client.ssh('bash -x mount_volume.sh')

    ssh_client.scp(os.path.join(SCRIPT_DIR, '..', 'install_puppet.sh'),
                   'install_puppet.sh')
    ssh_client.ssh('bash -x install_puppet.sh')

    certname = cert[:(0 - len('.pem'))]
    ssh_client.ssh("mkdir -p /var/lib/puppet/ssl/certs")
    ssh_client.ssh("mkdir -p /var/lib/puppet/ssl/private_keys")
    ssh_client.ssh("mkdir -p /var/lib/puppet/ssl/public_keys")
    ssh_client.ssh("chown -R puppet:root /var/lib/puppet/ssl")
    ssh_client.ssh("chown -R puppet:puppet /var/lib/puppet/ssl/private_keys")
    ssh_client.ssh("chmod 0771 /var/lib/puppet/ssl")
    ssh_client.ssh("chmod 0755 /var/lib/puppet/ssl/certs")
    ssh_client.ssh("chmod 0750 /var/lib/puppet/ssl/private_keys")
    ssh_client.ssh("chmod 0755 /var/lib/puppet/ssl/public_keys")

    for ssldir in ['/var/lib/puppet/ssl/certs/',
                   '/var/lib/puppet/ssl/private_keys/',
                   '/var/lib/puppet/ssl/public_keys/']:
        ssh_client.scp(os.path.join(ssldir, cert),
                       os.path.join(ssldir, cert))

    ssh_client.scp("/var/lib/puppet/ssl/crl.pem",
                   "/var/lib/puppet/ssl/crl.pem")
    ssh_client.scp("/var/lib/puppet/ssl/certs/ca.pem",
                   "/var/lib/puppet/ssl/certs/ca.pem")

    ssh_client.ssh("puppet agent "
                   "--environment %s "
                   "--server %s "
                   "--no-daemonize --verbose --onetime --pluginsync true "
                   "--certname %s" % (environment, puppetmaster, certname))

    ssh_client.ssh("reboot")


def build_server(
        client, name, image, flavor, cert, environment, puppetmaster, volume):
    key = None
    server = None

    create_kwargs = dict(image=image, flavor=flavor, name=name)

    key_name = 'launch-node-%s' % pwd.getpwuid(os.getuid()).pw_name
    if 'os-keypairs' in utils.get_extensions(client):
        print "Adding keypair"
        key = utils.add_keypair(client, key_name)
        create_kwargs['key_name'] = key_name
    server = client.servers.create(**create_kwargs)

    try:
        admin_pass = server.adminPass
        server = utils.wait_for_resource(server)
        if volume:
            vobj = client.volumes.create_server_volume(
                server.id, volume, None)
        if not vobj:
            raise Exception("Couldn't attach volume")

        bootstrap_server(server, admin_pass, key, cert, environment, name,
                         puppetmaster, volume)
        print('UUID=%s\nIPV4=%s\nIPV6=%s\n' % (server.id,
                                               server.accessIPv4,
                                               server.accessIPv6))
    except Exception:
        try:
            utils.delete_server(server)
        except Exception:
            print "Exception encountered deleting server:"
            traceback.print_exc()
        # Raise the important exception that started this
        raise


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("name", help="server name")
    parser.add_argument("--flavor", dest="flavor", default='1GB',
                        help="name (or substring) of flavor")
    parser.add_argument("--image", dest="image",
                        default="Ubuntu 12.04 LTS (Precise Pangolin) (PVHVM)",
                        help="image name")
    parser.add_argument("--environment", dest="environment",
                        default="production",
                        help="puppet environment name")
    parser.add_argument("--cert", dest="cert",
                        help="name of signed puppet certificate file (e.g., "
                        "hostname.example.com.pem)")
    parser.add_argument("--server", dest="server", help="Puppetmaster to use.",
                        default="ci-puppetmaster.openstack.org")
    parser.add_argument("--volume", dest="volume",
                        help="UUID of volume to attach to the new server.",
                        default=None)
    options = parser.parse_args()

    client = get_client()

    if options.cert:
        cert = options.cert
    else:
        cert = options.name + ".pem"

    if not os.path.exists(os.path.join("/var/lib/puppet/ssl/private_keys",
                                       cert)):
        raise Exception("Please specify the name of a signed puppet cert.")

    flavors = [f for f in client.flavors.list()
               if options.flavor in (f.name, f.id)]
    flavor = flavors[0]
    print "Found flavor", flavor

    images = [i for i in client.images.list()
              if (options.image.lower() in (i.id, i.name.lower()) and
                  not i.name.endswith('(Kernel)') and
                  not i.name.endswith('(Ramdisk)'))]

    if len(images) > 1:
        print "Ambiguous image name; matches:"
        for i in images:
            print i.name
        sys.exit(1)

    if len(images) == 0:
        print "Unable to find matching image; image list:"
        for i in client.images.list():
            print i.name
        sys.exit(1)

    image = images[0]
    print "Found image", image

    build_server(client, options.name, image, flavor, cert,
                 options.environment, options.server, options.volume)
    dns.print_dns(client, options.name)

if __name__ == '__main__':
    main()
