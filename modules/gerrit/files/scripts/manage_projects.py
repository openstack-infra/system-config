#! /usr/bin/env python
# Copyright (C) 2011 OpenStack, LLC.
# Copyright (c) 2012 Hewlett-Packard Development Company, L.P.
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

# - homepage: http://openstack.org
#   local-git-dir: /var/lib/git
#   gerrit-key: /home/gerrit2/review_site/etc/ssh_host_rsa_key
#   has-wiki: False
#   has-issues: False
#   has-downloads: False
# ---
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
import tempfile
import yaml

import github
import gerritlib.gerrit


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
                               '/home/gerrit2/projects.yaml')
configs = [config for config in yaml.load_all(open(PROJECTS_YAML))]
defaults = configs[0][0]
default_has_issues = defaults.get('has-issues', False)
default_has_downloads = defaults.get('has-downloads', False)
default_has_wiki = defaults.get('has-wiki', False)

LOCAL_GIT_DIR = defaults.get('local-git-dir', '/var/lib/git')
GERRIT_USER = defaults.get('gerrit-user')
GERRIT_KEY = defaults.get('gerrit-key')
GITHUB_SECURE_CONFIG = defaults.get('github-config',
                                    '/etc/github/github-projects.secure.config')

secure_config = ConfigParser.ConfigParser()
secure_config.read(GITHUB_SECURE_CONFIG)

# Project creation doesn't work via oauth
ghub = github.Github(secure_config.get("github", "username"),
                     secure_config.get("github", "password"))
orgs = ghub.get_user().get_orgs()
orgs_dict = dict(zip([o.login.lower() for o in orgs], orgs))

gerrit = gerritlib.gerrit.Gerrit('localhost',
                                 GERRIT_USER,
                                 29418,
                                 GERRIT_KEY)
project_list = gerrit.listProjects()

for section in configs[1]:
    project = section['project']
    options = section.get('options', dict())
    description = section.get('description', None)
    homepage = section.get('homepage', defaults.get('homepage', None))
    upstream = section.get('upstream', None)

    project_git = "%s.git" % project
    project_dir = os.path.join(LOCAL_GIT_DIR, project_git)

    # Find the project's repo
    project_split = project.split('/', 1)
    if len(project_split) > 1:
        repo_name = project_split[1]
    else:
        repo_name = project
    has_issues = 'has-issues' in options or default_has_issues
    has_downloads = 'has-downloads' in options or default_has_downloads
    has_wiki = 'has-wiki' in options or default_has_wiki
    org = orgs_dict[project_split[0].lower()]
    try:
        repo = org.get_repo(repo_name)
    except github.GithubException:
        repo = org.create_repo(repo_name,
                               homepage=homepage,
                               has_issues=has_issues,
                               has_downloads=has_downloads,
                               has_wiki=has_wiki)
    if description:
        repo.edit(repo_name, description=description)
    if homepage:
        repo.edit(repo_name, homepage=homepage)

    repo.edit(repo_name, has_issues=has_issues,
              has_downloads=has_downloads,
              has_wiki=has_wiki)

    if 'gerrit' not in [team.name for team in repo.get_teams()]:
        teams = org.get_teams()
        teams_dict = dict(zip([t.name.lower() for t in teams], teams))
        teams_dict['gerrit'].add_to_repos(repo)

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

            if not os.path.exists(project_dir):
                run_command("git --bare init %s" % project_dir)
                run_command("chown -R gerrit2:gerrit2 %s" % project_dir)

            ssh_env = dict(GIT_SSH='ssh -i %s -o StrictHostKeyChecking=no' %
                           GERRIT_KEY)
            run_command("git push %s HEAD:refs/heads/master" % remote_url,
                        env=ssh_env)
            run_command("git push --tags %s" % remote_url, env=ssh_env)
        finally:
            os.chdir('/tmp')
            run_command("rm -fr %s" % tmpdir)
