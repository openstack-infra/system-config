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
#   team-id: 153703
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
import re
import shlex
import subprocess
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


def fetch_config(project, remote_url, repo_path):
    status = git_command(repo_path, "fetch %s +refs/meta/config:"
                         "refs/remotes/gerrit-meta/config" % remote_url)
    if status != 0:
        print "Failed to fetch refs/meta/config for project: %s" % project
        return False
    # Because the following fails if executed more than once you should only
    # run fetch_config once in each repo.
    status = git_command(repo_path, "checkout -b config "
                            "remotes/gerrit-meta/config")
    if status != 0:
        print "Failed to checkout config for project: %s" % project
        return False

    return True


def copy_acl_config(project, repo_path, acl_config):
    if not os.path.exists(acl_config):
        return False

    acl_dest = os.path.join(repo_path, "project.config")
    status, _ = run_command("cp %s %s" %
                            (acl_config, acl_dest), status=True)
    if status == 0:
       status = git_command(repo_path, "diff-index --quiet HEAD --")
       if status != 0:
           return True
    return False


def push_acl_config(project, remote_url, repo_path):
    status = git_command(repo_path, "commit -a -m'Update project config.'")
    if status != 0:
        print "Failed to commit config for project: %s" % project
        return False
    status = git_command(repo_path, "push %s HEAD:refs/meta/config" %
                                                            remote_url)
    if status != 0:
        print "Failed to push config for project: %s" % project
        return False
    return True


def create_groups_file(project, gerrit, repo_path):
    acl_config = os.path.join(repo_path, "project.config")
    group_file = os.path.join(repo_path, "groups")
    uuids = {}
    for line in open(acl_config, 'r'):
        r = re.match(r'^\t.*group\s(.*)$', line)
        if r:
            group = r.group(1)
            query = "select group_uuid from " \
                    "account_groups where name = '%s'" % group
            data = gerrit.dbQuery(query)
            if data:
                for row in data:
                    if row["type"] == "row":
                        uuids[group] = row["columns"]["group_uuid"]
                        break
            else:
                return False
    if uuids:
        fp = open(group_file, 'w')
        for group, uuid in uuids.items():
            fp.write("%s\t%s\n"% (uuid, group))
        fp.close()
    return True


logging.basicConfig(level=logging.ERROR)

PROJECTS_YAML = os.environ.get('PROJECTS_YAML',
                               '/home/gerrit2/projects.yaml')
configs = [config for config in yaml.load_all(open(PROJECTS_YAML))]
defaults = config[0][0]
team_id = defaults['team-id']
default_has_issues = defaults.get('has-issues', False)
default_has_downloads = defaults.get('has-downloads', False)
default_has_wiki = defaults.get('has-wiki', False)

LOCAL_GIT_DIR = defaults.get('local-git-dir', '/var/lib/git')
GERRIT_KEY = defaults.get('gerrit-key',
                          '/home/gerrit2/review_site/etc/ssh_host_rsa_key')
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

for section in config[1]:
    project = section['project']
    options = section['options']
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
    try:
        repo = orgs_dict[project_split[0].lower()].get_repo(repo_name)
    except github.GithubException.GithubException:
        repo = ghub.get_user().create_repo(repo_name,
                                           homepage=homepage,
                                           has_issues=has_issues,
                                           has_downloads=has_downloads,
                                           team_id=team_id,
                                           has_wiki=has_wiki)
    if description:
        ghub.get_user().edit_repo(repo_name,
                                  description=description)
    if homepage:
        ghub.get_user().edit_repo(repo_name,
                                  homepage=homepage)

    ghub.get_user().edit_repo(repo_name,
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

    if 'acl_config' in section:
        tmpdir = tempfile.mkdtemp()
        try:
            repo_path = os.path.join(tmpdir, 'repo')
            ret, _  = run_command_status("git init %s" % repo_path)
            if ret != 0:
                continue
            if (fetch_config(project, remote_url, repo_path) and
                copy_acl_config(project, repo_path, section['acl_config']) and
                create_groups_file(project, gerrit, repo_path)):
                push_acl_config(project, remote_url, repo_path)
        finally:
            os.removedirs(tmpdir)
