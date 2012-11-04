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

# run_mirrors reads a project config file called projects.yaml
# It should look like:

# - project: PROJECT_NAME

import logging
import os
import subprocess
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

PROJECTS_YAML = os.environ.get('PROJECTS_YAML',
                               '/etc/openstackci/projects.yaml')
PIP_TEMP_DOWNLOAD = os.environ.get('PIP_TEMP_DOWNLOAD',
                                   '/var/lib/pip-download')
GIT_SOURCE = os.environ.get('GIT_SOURCE', 'https://github.com')
pip_command = '/usr/local/bin/pip install -M -U -I --exists-action=w ' \
              '--no-install %s'

run_command(pip_command % "pip")

(defaults, config) = [config for config in yaml.load_all(open(PROJECTS_YAML))]

for section in config:
    project = section['project']

    os.chdir(PIP_TEMP_DOWNLOAD)
    short_project = project.split('/')[1]
    if not os.path.isdir(short_project):
        run_command("git clone %s/%s.git %s" % (GIT_SOURCE, project,
                                                short_project))
    os.chdir(short_project)
    run_command("git fetch origin")

    for branch in run_command("git branch -a").split("\n"):
        branch = branch.strip()
        if (not branch.startswith("remotes/origin")
            or "origin/HEAD" in branch):
            continue
        run_command("git reset --hard %s" % branch)
        run_command("git clean -x -f -d -q")
        print("*********************")
        print("Fetching pip requires for %s:%s" % (project, branch))
        for requires_file in ("tools/pip-requires", "tools/test-requires"):
            if os.path.exists(requires_file):
                stanza = "-r %s" % requires_file
                run_command(pip_command % stanza)

