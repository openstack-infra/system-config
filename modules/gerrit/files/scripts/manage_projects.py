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

# manage_projects.py reads a project config file called projects.yaml
# It should look like:

# - project: PROJECT_NAME
#   options:
#    - has-wiki
#    - has-issues
#    - has-downloads
#    - has-pull-requests
#   homepage: Some homepage that isn't http://openstack.org
#   description: This is a great project
#   remote: https://gerrit.googlesource.com/gerrit
#   upstream: git://github.com/bushy/beards.git
#
# TODO: Add support for setting acls.

import ConfigParser
import logging
import os
import shlex
import subprocess
import sys
import tempfile
import yaml

import github
import gerritlib


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


def git_command(repo_dir, sub_cmd, env={}):
    git_dir = os.path.join(repo_dir, '.git')
    cmd = "git --git-dir=%s --work-tree=%s %s" % (git_dir, repo_dir, sub_cmd)
    status, _ = run_command(cmd, True, env)
    return status


def update_repo(project, repo_path):
    status = git_command(repo_path, "fetch origin +refs/meta/config:"
                            "refs/remotes/gerrit-meta/config")
    if status != 0:
        print "Failed to fetch refs/meta/config for project: %s" % project
        return False
    status = git_command(repo_path, "checkout -b config "
                            "remotes/gerrit-meta/config")
    if status != 0:
        print "Failed to checkout config for project: %s" % project
        return False

    return True


def copy_acl_config(project, repo_path, acl_config):
    if not os.path.exists(acl_config):
        return False

    status, _ = run_command("cp %s %s" %
                            (acl_config, repo_path), status=True)
    if status == 0:
       status = git_command(repo_path, "diff-index --quiet HEAD --")
       if status != 0:
           return True
    return False


def push_acl_config(project, repo_path):
    status = git_command(repo_path, "commit -a -m'Update project config.'")
    if status != 0:
        print "Failed to commit config for project: %s" % project
        return False
    status = git_command(repo_path, "push origin HEAD:refs/meta/config")
    if status != 0:
        print "Failed to push config for project: %s" % project
        return False
    return True


logging.basicConfig(level=logging.ERROR)

REPO_ROOT = sys.argv[1]
GERRIT_KEY = sys.argv[2]
PROJECTS_YAML = os.environ.get('PROJECTS_YAML',
                               '/home/gerrit2/projects.yaml')
GITHUB_SECURE_CONFIG = os.environ.get('GITHUB_SECURE_CONFIG',
                                      '/etc/github/github.secure.config')

secure_config = ConfigParser.ConfigParser()
secure_config.read(GITHUB_SECURE_CONFIG)

if secure_config.has_option("github", "oauth_token"):
    ghub = github.Github(secure_config.get("github", "oauth_token"))
else:
    ghub = github.Github(secure_config.get("github", "username"),
                         secure_config.get("github", "password"))
orgs = ghub.get_user().get_orgs()
orgs_dict = dict(zip([o.login.lower() for o in orgs], orgs))

gerrit = gerritlib.gerrit.Gerrit('localhost',
                                 'Gerrit Code Review',
                                 29418,
                                 GERRIT_KEY)
project_list = gerrit.listProjects()

config = yaml.load(open(PROJECTS_YAML))

for section in config:
    project = section['project']
    options = section['options']
    description = section.get('description', None)
    homepage = section.get('homepage', 'http://openstack.org')
    upstream = section.get('upstream', None)

    project_git = "%s.git" % project
    project_dir = os.path.join(REPO_ROOT, project_git)

    # Find the project's repo
    project_split = project.split('/', 1)
    if len(project_split) > 1:
        repo_name = project_split[1]
    else:
        repo_name = project
    has_issues = 'has-issues' in options
    has_downloads = 'has-downloads' in options
    has_wiki = 'has-wiki' in options
    try:
        repo = orgs_dict[project_split[0].lower()].get_repo(repo_name)
    except github.GithubException.GithubException:
        repo = ghub.get_user().create_repo(repo_name,
                                           homepage=homepage,
                                           has_issues=has_issues,
                                           has_downloads=has_downloads,
                                           team_id=153703,
                                           has_wiki=has_wiki)
    if description:
        ghub.get_user().edit_repo(repo_name,
                                  description=description)
    ghub.get_user().edit_repo(repo_name,
                              homepage=homepage,
                              has_issues=has_issues,
                              has_downloads=has_downloads,
                              has_wiki=has_wiki)

    if not os.path.exists(project_dir):
        run_command("git --bare init %s" % project_dir)
        run_command("chown -R gerrit2:gerrit2 %s" % project_dir)

    remote_url = "ssh://localhost:29418/%s" % project
    if project not in project_list:
        tmpdir = tempfile.mkdtemp()
        try:
            repo_path = os.path.join(tmpdir, 'repo')
            if upstream:
                run_command("git clone %(upstream)s %(repo_path)" %
                            dict(upstream=upstream, repo_path=repo_path))
            else:
                run_command("git init %s" % repo_path)
            os.chdir(repo_path)
            gerrit.createProject(project)
            ssh_env = dict(GIT_SSH='ssh -i %s -o "StrictHostKeyChecking no"' %
                           GERRIT_KEY)
            run_command("git push %s HEAD:refs/heads/master" % remote_url,
                        env=ssh_env)
            run_command("git push --tags %s" % remote_url, env=ssh_env)
        finally:
            os.removedirs(tmpdir)

    if acl_config in section:
        tmpdir = tempfile.mkdtemp()
        try:
            # Do we need to cache these repos instead of dealing with tmp dirs?
            # Cloning may be slow depending on the project.
            repo_path = os.path.join(tmpdir, 'repo')
            ret, out = run_command_status("git clone {remote_url} "
                "{repo_path}".format(remote_url=remote_url,
                                     repo_path=repo_path))
            if ret != 0:
                continue
            if (update_repo(project, repo_path) and
                #TODO: Copy group file?
                copy_acl_config(project, repo_path, section['acl_config'])):
                push_acl_config(project, repo_path)
        finally:
            os.removedirs(tmpdir)
