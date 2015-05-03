#!/usr/bin/env python
# Copyright (c) 2013 Hewlett-Packard Development Company, L.P.
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

import collections
import pprint
import yaml
import os


manifest = open('manifests/site.pp', 'r').read().split('\n')

groups = {}
fqdns = {}
common = []

current = None
current_keys = None

lines = iter(manifest)
for line in lines:
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
        name = line.split('"')[1]
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
pprint.pprint(dict(common=common, groups=groups, fqdns=fqdns))


def write_values(reverse_map, target, input_dict, source_vaues, root):
    outdir = os.path.join(root, target)
    if not os.path.exists(outdir):
        os.makedirs(outdir)
    for key, value in input_dict.items():
        output_dict = {}
        for name in value['keys']:
            reverse_map[name].append(dict(target=target, key=key))
            output_dict[name] = source_values[name]
        with open(os.path.join(outdir, '%s.yaml' % key), 'w') as outfile:
            outfile.write(yaml.dump(output_dict, default_flow_style=False))
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
