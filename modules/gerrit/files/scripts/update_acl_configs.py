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

# Update acl configs reads a project config file called projects.yaml
# It should look like:

# - project: PROJECT_NAME
#   options:
#   - close-pull
#   remote: https://gerrit.googlesource.com/gerrit
#   acl_config: /path/to/gerrit/project.config

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

def clone_project(project, repo_root, gerrit_url_root):
    project_dir = os.path.join(repo_root, project)

    if not os.path.exists(project_dir):
        status, _ = run_command("git clone %s%s %s" %
                    (gerrit_url_root, project, project_dir), status=True)
        if status != 0:
            print "Failed to clone project: %s" project
            return False
    return True

def update_repo(project, repo_root):
    project_dir = os.path.join(repo_root, project)

    status, _ = run_command("git fetch --git-dir=%s origin +refs/meta/config:"
                            "refs/remotes/gerrit-meta/config" %
                            project_dir, status=True)
    if status != 0:
        print "Failed to fetch refs/meta/config for project: %s" project
        return False
    status, _ = run_command("git checkout --git-dir=%s -b config "
                            "remotes/gerrit-meta/config" %
                            project_dir, status=True)
    if status != 0:
        print "Failed to checkout config for project: %s" project
        return False

    return True

def copy_acl_config(project, repo_root, acl_config):
    project_dir = os.path.join(repo_root, project)

    if not os.path.exists(acl_config):
        return False

    status, _ = run_command("cp %s %s" %
                            (acl_config, project_dir), status=True)
    if status == 0:
       status, _ = run_command("git diff-index --git-dir=%s --quiet HEAD --" %
                                project_dir, status=True)
       if status != 0:
           return True
    return False

def push_acl_config(project, repo_root):
    project_dir = os.path.join(repo_root, project)

    status, _ = run_command("git commit --git-dir=%s -a -m"
                            "'Update project config.'" %
                            project_dir, status=True)
    if status != 0:
        print "Failed to commit config for project: %s" project
        return False
    status, _ = run_command("git push --git-dir=%s origin "
                            "HEAD:refs/meta/config" %
                            project_dir, status=True)
    if status != 0:
        print "Failed to push config for project: %s" project
        return False
    return True

def checkout_master(project, repo_root):
    project_dir = os.path.join(repo_root, project)
    run_command("git checkout --git-dir=%s master", project_dir)
    run_command("git branch --git-dir=%s -D config", project_dir)

logging.basicConfig(level=logging.ERROR)

REPO_ROOT = sys.argv[1]
GERRIT_URL_ROOT = sys.argv[2]
PROJECTS_YAML = os.environ.get('PROJECTS_YAML',
                               '/home/gerrit2/projects.yaml')

config = yaml.load(open(PROJECTS_YAML))

exit_status = 0
for section in config:
    project = section['project']
    project_dir = os.path.join(REPO_ROOT, project)

    if (not section.get('acl_config') or
            not clone_project(project, REPO_ROOT, GERRIT_URL_ROOT)):
        continue

    if (update_repo(project, REPO_ROOT) and
            copy_acl_config(project, REPO_ROOT, section['acl_config'])):
        if not push_acl_config(project, REPO_ROOT):
            exit_status = 1
    else:
        exit_status = 1
    checkout_master(project, REPO_ROOT)

sys.exit(exit_status)
