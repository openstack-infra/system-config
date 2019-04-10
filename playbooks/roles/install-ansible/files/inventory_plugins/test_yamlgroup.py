# Copyright (C) 2018 Red Hat, Inc.
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

# Make coding more python3-ish
from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import os
import testtools
import mock
import yaml

from ansible.inventory.host import Host

from .yamlgroup import InventoryModule

FIXTURE_DIR = os.path.join(os.path.dirname(__file__),
                           'test-fixtures')

class TestInventory(testtools.TestCase):

    def test_yaml_groups(self):
        inventory = mock.MagicMock()

        results_yaml = os.path.join(FIXTURE_DIR, 'results.yaml')
        with open(results_yaml) as f:
            results = yaml.load(f, Loader=yaml.FullLoader)
            results = results['results']

        # Build the inventory list.  This is a list of Host objects
        # which are the keys in our results.yaml file, keyed by the
        # hostname (... I dunno, we're just tricking the inventory and
        # making something it's happy with)
        inventory.hosts = {}
        for host in results.keys():
            inventory.hosts[host] = Host(name=host)

        # Fake out add_group() and add_child() for the inventory
        # object to store our groups.
        inventory.groups = {}
        def add_group(group):
            inventory.groups[group] = []
        inventory.add_group = add_group
        def add_child(group, host):
            inventory.groups[group].append(host)
        inventory.add_child = add_child

        # Not really needed for unit test
        loader = mock.MagicMock()

        # This is all setup by ansible magic plugin/inventory stuff in
        # real-life, which gets the groups into the config object
        path = os.path.join(FIXTURE_DIR, 'groups.yaml')
        with open(path) as f:
            config_groups = yaml.load(f, Loader=yaml.FullLoader)
            config_groups = config_groups['groups']
        im = InventoryModule()
        im._read_config_data = mock.MagicMock()
        im._load_name = 'yamlgroup'
        im.get_option = mock.MagicMock(side_effect=lambda x: config_groups)

        im.parse(inventory, loader, path)

        # Now, for every host we have in our results, we should be
        # able to see it listed as a child of the groups it wants to
        # be in
        for host, groups in results.items():
            for group in groups:
                message=(
                    "The inventory does not have a group <%s>;"
                    "host <%s> should be in this group" % (group, host))
                self.assertEquals(group in inventory.groups, True, message)

                message=(
                    "The group <%s> does not contain host <%s>"
                    % (group, host))
                self.assertIn(host, inventory.groups[group], message)

            # Additionally, check this host hasn't managed to get into
            # any groups it is *not* supposed to be in
            for inventory_group, inventory_hosts in inventory.groups.items():
                if host in inventory_hosts:
                    message = ("The host <%s> should not be in group <%s>"
                               % (host, inventory_group))
                    self.assertTrue(inventory_group in groups, message)
