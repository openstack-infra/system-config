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

import argparse
import os
import shutil
import subprocess
import sys
import threading
import tempfile
import time
import traceback

import dns
import utils

import os_client_config
import paramiko
import shade

SCRIPT_DIR = os.path.dirname(sys.argv[0])

# Handy defaults
PROVIDER_DEFAULTS = {
    'rax-prod': {
        'cloud-name': 'openstackci-rax',
        'region': 'DFW',
        'flavor': '8 GB Performance',
        'image': 'Ubuntu 14.04 LTS (Trusty Tahr) (PVHVM)'
    },
    'rax-slave': {
        'cloud-name': 'openstackjenkins-rax',
        'region': 'DFW',
        'flavor': '8 GB Performance',
        'image': 'Ubuntu 14.04 LTS (Trusty Tahr) (PVHVM)'
    },
    'vexxhost' : {
        'cloud-name': 'openstackci-vexxhost',
        'region': 'ca-ymq-1',
        'flavor': 'v1-standard-8',
        'image': 'Ubuntu 16.04.1 LTS [2017-03-02]'
    },
}
DEFAULT_PROVIDER='rax-prod'

try:
    # This unactionable warning does not need to be printed over and over.
    import requests.packages.urllib3
    requests.packages.urllib3.disable_warnings()
except:
    pass


class JobDir(object):
    def __init__(self, keep=False):
        self.keep = keep
        self.root = tempfile.mkdtemp()
        self.inventory_root = os.path.join(self.root, 'inventory')
        os.makedirs(self.inventory_root)
        self.hosts = os.path.join(self.inventory_root, 'hosts')
        self.groups = os.path.join(self.inventory_root, 'groups')
        self.key = os.path.join(self.root, 'id_rsa')
        self.ansible_log = os.path.join(self.root, 'ansible_log.txt')
        # XXX if we need more, we might like to setup an ansible.cfg
        # file and use that rather than env vars.  See
        # zuul/launcher/ansiblelaunchserver.py as an example
        self.env = os.environ.copy()
        self.env['ANSIBLE_LOG_PATH'] = self.ansible_log

    def __enter__(self):
        return self

    def __exit__(self, etype, value, tb):
        if not self.keep:
            shutil.rmtree(self.root)


def run(cmd, **args):
    args['stdout'] = subprocess.PIPE
    args['stderr'] = subprocess.STDOUT
    print "Running: %s" % (cmd,)
    proc = subprocess.Popen(cmd, **args)
    out = ''
    for line in iter(proc.stdout.readline, ''):
        sys.stdout.write(line)
        sys.stdout.flush()
        out += line
    ret = proc.wait()
    print "Return code: %s" % (ret,)
    if ret != 0:
        raise subprocess.CalledProcessError(ret, cmd, out)
    return ret


def stream_syslog(ssh_client):
    try:
        ssh_client.ssh('tail -f /var/log/syslog')
    except Exception:
        print "Syslog stream terminated"


def bootstrap_server(server, key, name, volume_device, keep,
                     mount_path, fs_label, environment):

    ip = server.public_v4
    ssh_kwargs = dict(pkey=key)

    print("--- Running initial configuration on host %s ---" % ip)
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

    # Something up with RAX images that they have the ipv6 interface in
    # /etc/network/interfaces but eth0 hasn't noticed yet; reload it
    ssh_client.ssh('ifdown eth0 && ifup eth0')

    if server.public_v6:
        ssh_client.ssh('ping6 -c5 -Q 0x10 review.openstack.org '
                       '|| ping6 -c5 -Q 0x10 wiki.openstack.org')

    ssh_client.scp(os.path.join(SCRIPT_DIR, '..', 'make_swap.sh'),
                   'make_swap.sh')
    ssh_client.ssh('bash -x make_swap.sh')

    if volume_device:
        ssh_client.scp(os.path.join(SCRIPT_DIR, '..', 'mount_volume.sh'),
                       'mount_volume.sh')
        ssh_client.ssh('bash -x mount_volume.sh %s %s %s' %
                       (volume_device, mount_path, fs_label))

    # This next chunk should really exist as a playbook, but whatev
    ssh_client.scp(os.path.join(SCRIPT_DIR, '..', 'install_puppet.sh'),
                   'install_puppet.sh')
    ssh_client.ssh('bash -x install_puppet.sh')

    # Zero the ansible inventory cache so that next run finds the new server
    inventory_cache = '/var/cache/ansible-inventory/ansible-inventory.cache'
    if os.path.exists(inventory_cache):
        with open(inventory_cache, 'w'):
            pass

    with JobDir(keep) as jobdir:
        # Update the generated-groups file globally and incorporate it
        # into our inventory
        # Remove cloud and region from the environment to work
        # around a bug in occ
        expand_env = os.environ.copy()
        for env_key in expand_env.keys():
            if env_key.startswith('OS_'):
                expand_env.pop(env_key, None)
        expand_env['ANSIBLE_LOG_PATH'] = jobdir.ansible_log

        # Regenerate inventory cache, throwing an error if there is an issue
        # so that we don't generate a bogus groups file
        try:
            run(['/etc/ansible/hosts/openstack', '--list'],
                env=expand_env)
        except subprocess.CalledProcessError as e:
            print "Inventory regeneration failed"
            print e.output
            raise

        run('/usr/local/bin/expand-groups.sh',
            env=expand_env,
            stderr=subprocess.STDOUT)

        # Write out the private SSH key we generated
        with open(jobdir.key, 'w') as key_file:
            key.write_private_key(key_file)
        os.chmod(jobdir.key, 0o600)

        # Write out inventory
        with open(jobdir.hosts, 'w') as inventory_file:
            inventory_file.write(
                "{host} ansible_host={ip} ansible_user=root".format(
                    host=name, ip=server.interface_ip))

        os.symlink('/etc/ansible/hosts/generated-groups',
                   jobdir.groups)

        t = threading.Thread(target=stream_syslog, args=(ssh_client,))
        t.daemon = True
        t.start()

        ansible_cmd = [
            'ansible-playbook',
            '-i', jobdir.inventory_root, '-l', name,
            '--private-key={key}'.format(key=jobdir.key),
            "--ssh-common-args='-o StrictHostKeyChecking=no'",
            '-e', 'target={name}'.format(name=name),
        ]

        if environment is not None:
            ansible_cmd += [
                '-e',
                'puppet_environment={env}'.format(env=environment)]
        # Run the remote puppet apply playbook limited to just this server
        # we just created
        for playbook in [
                'set_hostnames.yml',
                'remote_puppet_adhoc.yaml']:
            run(ansible_cmd + [
                os.path.join(SCRIPT_DIR, '..', 'playbooks', playbook)],
                env=jobdir.env)

    try:
        ssh_client.ssh("reboot")
    except Exception as e:
        # Some init system kill the connection too fast after reboot.
        # Deal with it by ignoring ssh errors when rebooting.
        if e.rc == -1:
            pass
        else:
            raise


def build_server(cloud, name, image, flavor,
                 volume, keep, network, boot_from_volume, config_drive,
                 mount_path, fs_label, availability_zone, environment):
    key = None
    server = None

    create_kwargs = dict(image=image, flavor=flavor, name=name,
                         reuse_ips=False, wait=True,
                         boot_from_volume=boot_from_volume,
                         network=network,
                         config_drive=config_drive)

    if availability_zone:
        create_kwargs['availability_zone'] = availability_zone

    if volume:
        create_kwargs['volumes'] = [volume]

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

        server = cloud.get_openstack_vars(server)
        if volume:
            volume = cloud.get_volume(volume)
            volume_device = cloud.get_volume_attach_device(volume,
                                                           server['id'])
        else:
            volume_device = None
        bootstrap_server(server, key, name, volume_device, keep,
                         mount_path, fs_label, environment)
        print('UUID=%s\nIPV4=%s\nIPV6=%s\n' % (
            server.id, server.public_v4, server.public_v6))
    except Exception:
        print "****"
        print "Server %s failed to build!" % (server.id)
        try:
            if keep:
                print "Keeping as requested"
                # Write out the private SSH key we generated, as we
                # may not have got far enough for ansible to run
                with open('/tmp/%s.id_rsa' % server.id, 'w') as key_file:
                    key.write_private_key(key_file)
                    os.chmod(key_file.name, 0o600)
                    print "Private key saved in %s" % key_file.name
                print "Run to delete -> openstack server delete %s" % \
                    (server.id)
            else:
                cloud.delete_server(server.id, delete_ips=True)
        except Exception:
            print "Exception encountered deleting server:"
            traceback.print_exc()
        print "The original exception follows:"
        print "****"
        # Raise the important exception that started this
        raise

    return server


def main():
    try:
        has_provider = 'PROVIDER' in os.environ
        provider = os.environ.get('PROVIDER', DEFAULT_PROVIDER)
        arg_defaults = PROVIDER_DEFAULTS[provider]
    except KeyError:
        print("Could not find defaults for PROVIDER '%s'" % provider)
        sys.exit(1)

    parser = argparse.ArgumentParser(description=
                                     "Launch a new node. Specify --cloud or "
                                     " set PROVIDER to one of %s""" %
                                     (','.join(PROVIDER_DEFAULTS.keys())))
    parser.add_argument("name", help="server name")
    # --cloud is required if you don't choose a PROVIDER via environment
    parser.add_argument("--cloud", dest="cloud",
                        help="cloud name (default: %s)" %
                        arg_defaults['cloud-name'],
                        default=arg_defaults['cloud-name'])
    parser.add_argument("--region", dest="region",
                        default=arg_defaults['region'],
                        help="cloud region (default: %s)" %
                        arg_defaults['region'])
    parser.add_argument("--flavor", dest="flavor",
                        default=arg_defaults['flavor'],
                        help="name (or substring) of flavor (default: %s)" %
                        arg_defaults['flavor'])
    parser.add_argument("--image", dest="image",
                        default=arg_defaults['image'],
                        help="image name (default: %s)" % arg_defaults['image'])
    parser.add_argument("--environment", dest="environment",
                        help="Puppet environment to use",
                        default=None)
    parser.add_argument("--volume", dest="volume",
                        help="UUID of volume to attach to the new server.",
                        default=None)
    parser.add_argument("--mount-path", dest="mount_path",
                        help="Path to mount cinder volume at.",
                        default=None)
    parser.add_argument("--fs-label", dest="fs_label",
                        help="FS label to use when mounting cinder volume.",
                        default=None)
    parser.add_argument("--boot-from-volume", dest="boot_from_volume",
                        help="Create a boot volume for the server and use it.",
                        action='store_true',
                        default=False)
    parser.add_argument("--keep", dest="keep",
                        help="Don't clean up or delete the server on error.",
                        action='store_true',
                        default=False)
    parser.add_argument("--verbose", dest="verbose", default=False,
                        action='store_true',
                        help="Be verbose about logging cloud actions")
    parser.add_argument("--network", dest="network", default=None,
                        help="network label to attach instance to")
    parser.add_argument("--config-drive", dest="config_drive",
                        help="Boot with config_drive attached.",
                        action='store_true',
                        default=False)
    parser.add_argument("--az", dest="availability_zone", default=None,
                        help="AZ to boot in.")
    options = parser.parse_args()

    shade.simple_logging(debug=options.verbose)

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

    # TODO(ianw): print all the things ... this is enough for sanity
    print """
I am about to build a server:

 * In cloud: %(cloud)s %(region)s
 * With name: %(name)s
 * Using image: %(image)s
 * Of flavor: %(flavor)s
 * If something fails, I will %(keep)s the server

OK? [y/n]""" % dict(cloud=options.cloud,
                    region="[region %s]" % options.region
                    if options.region else "",
                    name=options.name,
                    image=image.name,
                    flavor=flavor.name,
                    keep="keep" if options.keep else "destroy")
    do_it = raw_input().lower()
    if not do_it == 'y':
        print "Cancelling"
        sys.exit(0)

    sys.exit(1)
    server = build_server(cloud, options.name, image, flavor,
                          options.volume, options.keep,
                          options.network, options.boot_from_volume,
                          options.config_drive,
                          options.mount_path, options.fs_label,
                          options.availability_zone,
                          options.environment)
    dns.print_dns(cloud, server)

if __name__ == '__main__':
    main()
