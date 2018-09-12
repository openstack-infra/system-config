# Copyright (c) 2018 Red Hat, Inc.
# GNU General Public License v3.0+ (see COPYING.GPL or https://www.gnu.org/licenses/gpl-3.0.txt)

import fnmatch
import os

from ansible.plugins.inventory import BaseFileInventoryPlugin

DOCUMENTATION = '''
    inventory: yamlgroup
    version_added: "2.8"
    short_description: Simple group manipulation for existing hosts
    description:
        - YAML based inventory that only manipulates group membership for
          existing hosts.
    options:
      yaml_extensions:
        description: list of 'valid' extensions for files containing YAML
        type: list
        default: ['.yaml', '.yml', '.json']
        env:
          - name: ANSIBLE_YAML_FILENAME_EXT
          - name: ANSIBLE_INVENTORY_PLUGIN_EXTS
        ini:
          - key: yaml_valid_extensions
            section: defaults
          - section: inventory_plugin_yaml
            key: yaml_valid_extensions
      groups:
        description: dict with group name as key and list of fnmatch patterns
        type: dict
        default: {}
      disabled:
        description: list of hosts to remove from the inventory
        type: list
        default: []
'''
EXAMPLES = '''
plugin: yamlgroup
disabled:
  - bad.example.com
groups:
  amazing:
    - fullhost.example.com
    - amazing*
'''


class InventoryModule(BaseFileInventoryPlugin):

    NAME = 'yamlgroup'

    def verify_file(self, path):

        valid = False
        if super(InventoryModule, self).verify_file(path):
            file_name, ext = os.path.splitext(path)
            if not ext or ext in self.get_option('yaml_extensions'):
                valid = True
        return valid

    def parse(self, inventory, loader, path, cache=True):
        ''' parses the inventory file '''

        super(InventoryModule, self).parse(inventory, loader, path)

        self._read_config_data(path)

        disabled = self.get_option('disabled', [])
        remove = set()
        for disabled_host in disabled:
            for existing in self.inventory.hosts:
                if fnmatch.fnmatch(existing, disabled_host):
                    remove.add(disabled_host)
        for disabled_host in remove:
            self.inventory.remove_host(disabled_host)

        groups = self.get_option('groups')

        found_groups = {}

        for group, hosts in groups.items():
            if not isinstance(hosts, list):
                hosts = [hosts]
            for candidate in hosts:
                for existing in self.inventory.hosts:
                    if fnmatch.fnmatch(existing, candidate):
                        found_groups.setdefault(group, [])
                        found_groups.append(existing)

        for group, hosts in found_groups.items():
            self.inventory.add_group(group)
            for host in hosts:
                self.inventory.add_child(group, host)
