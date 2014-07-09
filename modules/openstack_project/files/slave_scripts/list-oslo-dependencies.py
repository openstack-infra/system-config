#!/usr/bin/env python
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
"""Given a list of requirements files and a path to the programs file
in the openstack/governance repo, print a list of the requirements
that are Oslo libraries.

"""

from __future__ import print_function

import argparse
import fileinput
import os

import pkg_resources
import yaml


def main():
    parser = argparse.ArgumentParser(
        description='list dependencies on oslo libraries',
    )
    parser.add_argument(
        'program_file',
        help='location of openstack/governance/reference/programs.yaml',
    )
    parser.add_argument(
        'requirements_files',
        nargs='+',
        help='requirements file names',
    )
    args = parser.parse_args()

    # Read the programs file to make a list of Oslo libraries.
    with open(args.program_file, 'r') as pf:
        program_data = yaml.load(pf)
    oslo_data = program_data['Common Libraries']
    oslo_projects = oslo_data['projects']
    oslo_libnames = set([os.path.basename(p['repo'])
                         for p in oslo_projects])

    # Process the requirements files.
    for line in fileinput.input(args.requirements_files):
        line = line.strip()
        if not line:
            continue
        if line.startswith('#'):
            continue
        try:
            project_name = pkg_resources.Requirement.parse(line).project_name
        except ValueError:
            continue
        if project_name in oslo_libnames:
            print(project_name)


if __name__ == '__main__':
    main()
