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

# Fetch remotes reads a project config file called projects.yaml
# It should look like:

# - homepage: http://openstack.org
#   team-id: 153703
#   has-wiki: False
#   has-issues: False
#   has-downloads: False
# ---
# - project: PROJECT_NAME
#   options:
#   - remote: https://gerrit.googlesource.com/gerrit


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

REPO_ROOT = os.environ.get('REPO_ROOT',
                           '/home/gerrit2/review_site/git')
PROJECTS_YAML = os.environ.get('PROJECTS_YAML',
                               '/home/gerrit2/projects.yaml')

(defaults, config) = [config for config in yaml.load_all(open(PROJECTS_YAML))]

for section in config:
    project = section['project']

    if 'remote' not in section:
        continue

    project_git = "%s.git" % project
    os.chdir(os.path.join(REPO_ROOT, project_git))

    # Make sure that the specified remote exists
    remote_url = section['remote']
    # We could check if it exists first, but we're ignoring output anyway
    # So just try to make it, and it'll either make a new one or do nothing
    run_command("git remote add -f upstream %s" % remote_url)
    # Fetch new revs from it
    run_command("git remote update upstream")
