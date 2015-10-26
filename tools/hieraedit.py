#!/usr/bin/env python

# Copyright 2013 OpenStack Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

import argparse
import os
import yaml
import tempfile
import pwd
import grp
from collections import OrderedDict

# from:
# http://stackoverflow.com/questions/5121931/in-python-how-can-you-load-yaml-mappings-as-ordereddicts flake8: noqa
_mapping_tag = yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG
class MyLoader(yaml.Loader):
    def __init__(self, stream):
        super(MyLoader, self).__init__(stream)
        def dict_constructor(loader, node):
            return OrderedDict(loader.construct_pairs(node))
        self.add_constructor(_mapping_tag, dict_constructor)
# end from

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
    def __init__(self, *args, **kwargs):
        super(MyDumper, self).__init__(*args, **kwargs)
        def dict_representer(dumper, data):
            return dumper.represent_dict(data.iteritems())
        self.add_representer(OrderedDict, dict_representer)
        
    def increase_indent(self, flow=False, indentless=False):
        return super(MyDumper, self).increase_indent(flow, False)
#end from

parser = argparse.ArgumentParser(description='Edit hiera yaml.')
parser.add_argument('--yaml', help='the path to the hiera yaml file')
parser.add_argument('key', help='the key')
parser.add_argument('value', help='the value', nargs='?')
parser.add_argument('-f', dest='file', help='file to read in as value')

args = parser.parse_args()
data = yaml.load(open(args.yaml), Loader=MyLoader)
assert type(data) == OrderedDict # OrderedDict object

changed = False
if args.value:
    data[args.key] = args.value
    changed = True
if args.file:
    data[args.key] = open(args.file).read()
    changed = True
print data[args.key]

if changed:
    dn = os.path.dirname(args.yaml)
    (out, fn) = tempfile.mkstemp(dir=dn)
    os.write(out, yaml.dump(data, default_flow_style=False, Dumper=MyDumper))
    os.close(out)
    os.chown(fn, pwd.getpwnam('puppet').pw_uid, grp.getgrnam('puppet').gr_gid)
    os.rename(fn, args.yaml)
