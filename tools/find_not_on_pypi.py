#!/usr/bin/env python
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
