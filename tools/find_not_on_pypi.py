#!/usr/bin/env python
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
"""
Print a list of the names of projects that appear in the projects
input file for jjb with pypi-jobs, but that do not appear on PyPI
using the same name.

Requires PyYAML and yolk.

"""

import subprocess

import yaml

data = yaml.load(
    open('modules/openstack_project/files/'
         'jenkins_job_builder/config/projects.yaml',
         'r')
)

for p in data:
    if 'pypi-jobs' in p['project']['jobs']:
        name = p['project']['name']
        try:
            answer = subprocess.check_output(
                ['yolk', '-S', 'name=%s' % name]
            )
            answer = answer.strip()
        except subprocess.CalledProcessError:
            answer = None
        if not answer:
            print name
