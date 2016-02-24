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

import sys
import os
import time
import traceback
import argparse

import dns
import utils

import os_client_config
import paramiko
import shade

SCRIPT_DIR = os.path.dirname(sys.argv[0])

try:
    # This unactionable warning does not need to be printed over and over.
    import requests.packages.urllib3
    requests.packages.urllib3.disable_warnings()
except:
    pass


def bootstrap_server(server, key, cert, environment, name,
                     puppetmaster, volume, floating_ip_pool):
    ip = server.public_v4
    ssh_kwargs = dict(pkey=key)

    print 'Public IP', ip
    for username in ['root', 'ubuntu', 'centos', 'admin']:
        ssh_client = utils.ssh_connect(ip, username, ssh_kwargs, timeout=600)
        if ssh_client:
            break

    if not ssh_client:
        raise Exception("Unable to log in via SSH")

    # cloud-init puts the "please log in as user foo" message and
    # subsequent exit() in root's authorized_keys -- overwrite it with
    # a normal version to get root login working again.
    if username != 'root':
        ssh_client.ssh("sudo cp ~/.ssh/authorized_keys"
                       " ~root/.ssh/authorized_keys")
        ssh_client.ssh("sudo chmod 644 ~root/.ssh/authorized_keys")
        ssh_client.ssh("sudo chown root.root ~root/.ssh/authorized_keys")

    ssh_client = utils.ssh_connect(ip, 'root', ssh_kwargs, timeout=600)

    if server.public_v6:
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
    shortname = name.split('.')[0]
    with ssh_client.open('/etc/hosts', 'w') as f:
        f.write('127.0.0.1 localhost\n')
        f.write('127.0.1.1 %s %s\n' % (name, shortname))
    with ssh_client.open('/etc/hostname', 'w') as f:
        f.write('%s\n' % (shortname,))
    ssh_client.ssh("hostname %s" % (name,))
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

    (rc, output) = ssh_client.ssh(
        "puppet agent "
        "--environment %s "
        "--server %s "
        "--detailed-exitcodes "
        "--no-daemonize --verbose --onetime --pluginsync true "
        "--certname %s" % (environment, puppetmaster, certname), error_ok=True)
    utils.interpret_puppet_exitcodes(rc, output)

    try:
        ssh_client.ssh("reboot")
    except Exception as e:
        # Some init system kill the connection too fast after reboot.
        # Deal with it by ignoring ssh errors when rebooting.
        if e.rc == -1:
            pass
        else:
            raise


def build_server(cloud, name, image, flavor, cert, environment,
                 puppetmaster, volume, keep, net_label,
                 floating_ip_pool, boot_from_volume,
                 config_drive):
    key = None
    server = None

    create_kwargs = dict(image=image, flavor=flavor, name=name,
                         reuse_ips=False, wait=True, config_drive=config_drive)

    #TODO: test with rax
    #TODO: use shade
    if boot_from_volume:
        block_mapping = [{
            'boot_index': '0',
            'delete_on_termination': True,
            'destination_type': 'volume',
            'uuid': image.id,
            'source_type': 'image',
            'volume_size': '50',
        }]
        create_kwargs['image'] = None
        create_kwargs['block_device_mapping_v2'] = block_mapping

    #TODO: use shade
    #if net_label:
    #    nics = []
    #    for net in client.networks.list():
    #        if net.label == net_label:
    #            nics.append({'net-id': net.id})
    #    create_kwargs['nics'] = nics

    key_name = 'launch-%i' % (time.time())
    key = paramiko.RSAKey.generate(2048)
    public_key = key.get_name() + ' ' + key.get_base64()
    cloud.create_keypair(key_name, public_key)
    create_kwargs['key_name'] = key_name

    try:
        server = cloud.create_server(**create_kwargs)
    except Exception:
        try:
            cloud.delete_keypair(key_name)
        except Exception:
            print "Exception encountered deleting keypair:"
            traceback.print_exc()
        raise

    try:
        cloud.delete_keypair(key_name)

        # TODO: use shade
        if volume:
            raise Exception("not implemented")
            #vobj = client.volumes.create_server_volume(
            #    server.id, volume, None)
            #if not vobj:
            #    raise Exception("Couldn't attach volume")

        server = cloud.get_openstack_vars(server)
        bootstrap_server(server, key, cert, environment, name,
                         puppetmaster, volume, floating_ip_pool)
        print('UUID=%s\nIPV4=%s\nIPV6=%s\n' % (server.id,
                                               server.accessIPv4,
                                               server.accessIPv6))
    except Exception:
        try:
            if keep:
                print "Server failed to build, keeping as requested."
            else:
                cloud.delete_server(server.id, delete_ips=True)
        except Exception:
            print "Exception encountered deleting server:"
            traceback.print_exc()
        # Raise the important exception that started this
        raise

    return server


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("name", help="server name")
    parser.add_argument("--cloud", dest="cloud", required=True,
                        help="cloud name")
    parser.add_argument("--region", dest="region",
                        help="cloud region")
    parser.add_argument("--flavor", dest="flavor", default='1GB',
                        help="name (or substring) of flavor")
    parser.add_argument("--image", dest="image",
                        default="Ubuntu 14.04 LTS (Trusty Tahr) (PVHVM)",
                        help="image name")
    parser.add_argument("--environment", dest="environment",
                        default="production",
                        help="puppet environment name")
    parser.add_argument("--cert", dest="cert",
                        help="name of signed puppet certificate file (e.g., "
                        "hostname.example.com.pem)")
    parser.add_argument("--server", dest="server", help="Puppetmaster to use.",
                        default="puppetmaster.openstack.org")
    parser.add_argument("--volume", dest="volume",
                        help="UUID of volume to attach to the new server.",
                        default=None)
    parser.add_argument("--boot-from-volume", dest="boot_from_volume",
                        help="Create a boot volume for the server and use it.",
                        action='store_true',
                        default=False)
    parser.add_argument("--keep", dest="keep",
                        help="Don't clean up or delete the server on error.",
                        action='store_true',
                        default=False)
    parser.add_argument("--net-label", dest="net_label", default='',
                        help="network label to attach instance to")
    parser.add_argument("--fip-pool", dest="floating_ip_pool", default=None,
                        help="pool to assign floating IP from")
    parser.add_argument("--config-drive", dest="config_drive",
                        help="Boot with config_drive attached.",
                        action='store_true',
                        default=False)
    options = parser.parse_args()

    if options.cert:
        cert = options.cert
    else:
        cert = options.name + ".pem"

    if not os.path.exists(os.path.join("/var/lib/puppet/ssl/private_keys",
                                       cert)):
        raise Exception("Please specify the name of a signed puppet cert.")

    cloud_kwargs = {}
    if options.region:
        cloud_kwargs['region_name'] = options.region
    cloud_config = os_client_config.OpenStackConfig().get_one_cloud(
        options.cloud, **cloud_kwargs)

    cloud = shade.OpenStackCloud(cloud_config)

    flavor = cloud.get_flavor(options.flavor)
    if flavor:
        print "Found flavor", flavor.name
    else:
        print "Unable to find matching flavor; flavor list:"
        for i in cloud.list_flavors():
            print i.name
        sys.exit(1)

    image = cloud.get_image_exclude(options.image, 'deprecated')
    if image:
        print "Found image", image.name
    else:
        print "Unable to find matching image; image list:"
        for i in cloud.list_images():
            print i.name
        sys.exit(1)

    if options.volume:
        print "The --volume option does not support cinder; until it does"
        print "it should not be used."
        sys.exit(1)

    server = build_server(cloud, options.name, image, flavor, cert,
                          options.environment, options.server,
                          options.volume, options.keep,
                          options.net_label, options.floating_ip_pool,
                          options.boot_from_volume, options.config_drive)
    dns.shade_print_dns(server)
    # Remove the ansible inventory cache so that next run finds the new
    # server
    if os.path.exists('/var/cache/ansible-inventory/ansible-inventory.cache'):
        os.unlink('/var/cache/ansible-inventory/ansible-inventory.cache')
    os.system('/usr/local/bin/expand-groups.sh')

if __name__ == '__main__':
    main()
