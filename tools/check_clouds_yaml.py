#! /usr/bin/env python

# Copyright 2018 Red Hat
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os
import openstack
import re
import sys
import tempfile

FILES_TO_CHECK = (
    'playbooks/templates/clouds/nodepool_builder_clouds.yaml.j2',
    'playbooks/templates/clouds/nodepool_launcher_clouds.yaml.j2',
    'playbooks/templates/clouds/bridge_all_clouds.yaml.j2',
    'playbooks/templates/clouds/bridge_clouds.yaml.j2',
)


def check_files():

    with tempfile.TemporaryDirectory() as tempdir:
        for file in FILES_TO_CHECK:
            # These are actually erb files that have templating in
            # them, we just rewrite them with a string in there for
            # the parser to read, as the <>'s can confuse yaml
            # depending on how they're quoted in the file
            temp = open(os.path.join(tempdir,
                                     os.path.basename(file)), 'w')
            in_file = open(file, 'r')
            for line in in_file:
                line = re.sub(r'{{.*}}', 'loremipsum', line)
                temp.write(line)
            temp.close()

            try:
                print("Checking parsing of %s" % file)
                c = openstack.config.OpenStackConfig(config_files=[temp.name])
            except Exception as e:
                print("Error parsing : %s" % file)
                print(e)
                sys.exit(1)

def main():
    check_files()

if __name__ == "__main__":
    sys.exit(main())
