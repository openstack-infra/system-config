#! /usr/bin/env python
# Copyright (C) 2011 OpenStack, LLC.
#
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

# Make local repos reads a project config file called projects.yaml
# It should look like:

# - project: PROJECT_NAME
#   remote: https://gerrit.googlesource.com/gerrit

# TODO: add support for
#         ssh -p 29418 localhost gerrit -name create-project PROJECT

import logging
import os
import subprocess
import sys
import shlex
import yaml

def run_command(cmd, status=False, env={}):
    cmd_list = shlex.split(str(cmd))
    newenv = os.environ
    newenv.update(env)
    p = subprocess.Popen(cmd_list, stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT, env=newenv)
    (out, nothing) = p.communicate()
    if status:
        return (p.returncode, out.strip())
    return out.strip()


def run_command_status(cmd, env={}):
    return run_command(cmd, True, env)


logging.basicConfig(level=logging.ERROR)

REPO_ROOT = sys.argv[1]
PROJECTS_YAML = os.environ.get('PROJECTS_YAML',
                               '/home/gerrit2/projects.yaml')

config = yaml.load(open(PROJECTS_YAML))

for section in config:
    project = section['project']

    project_git = "%s.git" % project
    project_dir = os.path.join(REPO_ROOT, project_git)

    if os.path.exists(project_dir):
        continue

    run_command("git --bare init --shared=group %s" % project_dir)
