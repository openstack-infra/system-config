#!/usr/bin/env python
# Copyright (c) 2015 Hewlett-Packard Development Company, L.P.
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
# See the License for the specific language governing permissions and
# limitations under the License.

# This is a utility intended to split a single common.yaml file from
# a hieradata dir into a common.yaml / group/$::group.yaml / fqdn/$::fqdn.yaml
# structure.
# Values associated with the default node go into common.yaml
# Values associated with a node that has a group and is specified with a
# regex go into the group
# Values associated with a node that has a group but specifies a specific host
# will go into the fqdn file if they do not also appead in a group-related
# host.
#
# This utility is not intended to solve all problems and is not intended to be
# run on the same data twice. It's a one-off helper script, and it's
# potentially destructure. So be prepared to have a backup of your common.yaml
# file you can revert to after you inspect the output if it got something wrong

import collections
import pprint
import yaml
import os


groups = {}
fqdns = {}
common = []

current = None
current_keys = None

# from:
# http://stackoverflow.com/questions/8640959/how-can-i-control-what-scalar-form-pyyaml-uses-for-my-data  flake8: noqa
def should_use_block(value):
    for c in u"\u000a\u000d\u001c\u001d\u001e\u0085\u2028\u2029":
        if c in value:
            return True
    return False

def my_represent_scalar(self, tag, value, style=None):
    if style is None:
        if should_use_block(value):
             style='|'
        else:
            style = self.default_style

    node = yaml.representer.ScalarNode(tag, value, style=style)
    if self.alias_key is not None:
        self.represented_objects[self.alias_key] = node
    return node

yaml.representer.BaseRepresenter.represent_scalar = my_represent_scalar
# end from
# from: http://pyyaml.org/ticket/64
class MyDumper(yaml.Dumper):
    def increase_indent(self, flow=False, indentless=False):
        return super(MyDumper, self).increase_indent(flow, False)
#end from
manifest_path = os.path.abspath(
    os.path.join(os.path.dirname(__file__), '..', 'manifests/site.pp'))

with open(manifest_path, 'r') as manifest:
    for line in manifest:
        if line.startswith('#'):
            continue
        if 'node default' in line:
            current_keys = common
            continue
        elif line.startswith('node'):
            current_keys = list()
            current = dict(keys=current_keys)
            if '/' in line:
                name = line.split('/')[1]
                groups[name] = current
            else:
                name = line.split("'")[1]
                fqdns[name] = current
            continue
        if '$group' in line:
            if '"' in line:
                name = line.split('"')[1]
            elif "'" in line:
                name = line.split("'")[1]
            current['group'] = name
        if 'hiera' in line:
            key = line.split("'")[1]
            if key not in common:
                current_keys.append(key)


new_groups = {}
for value in groups.values():
    new_groups[value['group']] = dict(keys=value['keys'])
groups = new_groups

# Trim group duplicates to just be in the group
for key, value in fqdns.items():
    if 'group' in value:
        new_keys = []
        for possible_key in value['keys']:
            if possible_key not in groups[value['group']]['keys']:
                new_keys.append(possible_key)
        value['keys'] = new_keys

# Print the values so that the person running can verify what's going on
pprint.pprint(dict(common=common, groups=groups, fqdns=fqdns))


def write_values(reverse_map, target, input_dict, source_vaues, root):
    outdir = os.path.join(root, target)
    if not os.path.exists(outdir):
        os.makedirs(outdir)
    for key, value in input_dict.items():
        output_dict = {}
        for name in value['keys']:
            reverse_map[name].append(dict(target=target, key=key))
            if name in source_values:
                output_dict[name] = source_values[name]
            else:
                print "Requested key not in common.yaml", name
        with open(os.path.join(outdir, '%s.yaml' % key), 'w') as outfile:
            outfile.write(yaml.dump(
                output_dict, default_flow_style=False, Dumper=MyDumper))
    return reverse_map


def write_common_values(input_dict, source_values, root):
    outdir = root
    if not os.path.exists(outdir):
        os.makedirs(outdir)
    output_dict = {}
    for name in input_dict:
        output_dict[name] = source_values[name]
    with open(os.path.join(outdir, 'common.yaml'), 'w') as outfile:
        outfile.write(yaml.dump(output_dict, default_flow_style=False))


if os.path.exists('/etc/puppet/hieradata/production/common.yaml'):
    source_values = yaml.load(
        open('/etc/puppet/hieradata/production/common.yaml'))
    root = '/etc/puppet/hieradata/production'
else:
    def get_default():
        return "Default data"
    source_values = collections.defaultdict(get_default)
    root = 'testoutput'


write_common_values(common, source_values, root)
reverse_map = collections.defaultdict(list)
reverse_map = write_values(reverse_map, 'fqdn', fqdns, source_values, root)
reverse_map = write_values(reverse_map, 'group', groups, source_values, root)


for key, value in reverse_map.items():
    if len(value) > 1:
        print "Key %s duplicated in %r" % (key, value)
