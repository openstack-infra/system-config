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
#   gerrit-host: review.openstack.org
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
#   acl_config: /path/to/gerrit/project.config


import ConfigParser
import logging
import os
import re
import shlex
import subprocess
import tempfile
import yaml

import github
import gerritlib.gerrit


logging.basicConfig(level=logging.ERROR)
log = logging.getLogger("manage_projects")


def run_command(cmd, status=False, env={}):
    cmd_list = shlex.split(str(cmd))
    newenv = os.environ
    newenv.update(env)
    log.debug("Executing command: %s" % " ".join(cmd_list))
    p = subprocess.Popen(cmd_list, stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT, env=newenv)
    (out, nothing) = p.communicate()
    log.debug("Return code: %s" % p.returncode)
    log.debug("Command said: %s" % out.strip())
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


def git_command_output(repo_dir, sub_cmd, env={}):
    git_dir = os.path.join(repo_dir, '.git')
    cmd = "git --git-dir=%s --work-tree=%s %s" % (git_dir, repo_dir, sub_cmd)
    status, out = run_command(cmd, True, env)
    return (status, out)


def fetch_config(project, remote_url, repo_path, env={}):
    status = git_command(repo_path, "fetch %s +refs/meta/config:"
                         "refs/remotes/gerrit-meta/config" % remote_url, env)
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
        status = git_command(repo_path, "diff --quiet HEAD")
        if status != 0:
            return True
    return False


def push_acl_config(project, remote_url, repo_path, env={}):
    cmd = "commit -a -m'Update project config.' --author='Openstack Project " \
            "Creator <openstack-infra@lists.openstack.org>'"
    status = git_command(repo_path, cmd)
    if status != 0:
        print "Failed to commit config for project: %s" % project
        return False
    status, out = git_command_output(repo_path,
                         "push %s HEAD:refs/meta/config" %
                         remote_url, env)
    if status != 0:
        print "Failed to push config for project: %s" % project
        print out
        return False
    return True


def _get_group_uuid(gerrit, group):
    query = "select group_uuid from account_groups where name = '%s'" % group
    data = gerrit.dbQuery(query)
    if data:
        for row in data:
            if row["type"] == "row":
                return row["columns"]["group_uuid"]
    return None


def get_group_uuid(gerrit, group):
    uuid = _get_group_uuid(gerrit, group)
    if uuid:
        return uuid
    gerrit.createGroup(group)
    uuid = _get_group_uuid(gerrit, group)
    if uuid:
        return uuid
    return None


def create_groups_file(project, gerrit, repo_path):
    acl_config = os.path.join(repo_path, "project.config")
    group_file = os.path.join(repo_path, "groups")
    uuids = {}
    for line in open(acl_config, 'r'):
        r = re.match(r'^\s+.*group\s+(.*)$', line)
        if r:
            group = r.group(1)
            if group in uuids.keys():
                continue
            uuid = get_group_uuid(gerrit, group)
            if uuid:
                uuids[group] = uuid
            else:
                return False
    if uuids:
        with open(group_file, 'w') as fp:
            for group, uuid in uuids.items():
                fp.write("%s\t%s\n" % (uuid, group))
    status = git_command(repo_path, "add groups")
    if status != 0:
        print "Failed to add groups file for project: %s" % project
        return False
    return True


def make_ssh_wrapper(gerrit_user, gerrit_key):
    (fd, name) = tempfile.mkstemp(text=True)
    os.write(fd, '#!/bin/bash\n')
    os.write(fd,
             'ssh -i %s -l %s -o "StrictHostKeyChecking no" $@\n' %
             (gerrit_key, gerrit_user))
    os.close(fd)
    os.chmod(name, 755)
    return dict(GIT_SSH=name)


PROJECTS_YAML = os.environ.get('PROJECTS_YAML',
                               '/home/gerrit2/projects.yaml')
configs = [config for config in yaml.load_all(open(PROJECTS_YAML))]
defaults = configs[0][0]
default_has_issues = defaults.get('has-issues', False)
default_has_downloads = defaults.get('has-downloads', False)
default_has_wiki = defaults.get('has-wiki', False)

LOCAL_GIT_DIR = defaults.get('local-git-dir', '/var/lib/git')
GERRIT_HOST = defaults.get('gerrit-host')
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
ssh_env = make_ssh_wrapper(GERRIT_USER, GERRIT_KEY)
try:

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
        try:
            org = orgs_dict[project_split[0].lower()]
        except KeyError:
            # We do not have control of this github org ignore the project.
            continue
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
                    run_command("git clone %(upstream)s %(repo_path)s" %
                                dict(upstream=upstream, repo_path=repo_path))
                else:
                    run_command("git init %s" % repo_path)
                    with open(os.path.join(repo_path,
                                           ".gitreview"), 'w') as gitreview:
                        gitreview.write("""
[gerrit]
host=%s
port=29418
project=%s
""" % (GERRIT_HOST, project_git))
                    git_command(repo_path, "add .gitreview")
                    cmd = "commit -a -m'Added .gitreview' --author=" \
                            "'Openstack Project Creator " \
                            "<openstack-infra@lists.openstack.org>'"
                    git_command(repo_path, cmd)
                gerrit.createProject(project)

                if not os.path.exists(project_dir):
                    run_command("git --bare init %s" % project_dir)
                    run_command("chown -R gerrit2:gerrit2 %s" % project_dir)

                git_command(repo_path,
                            "push --all %s" % remote_url,
                            env=ssh_env)
                git_command(repo_path,
                            "push --tags %s" % remote_url, env=ssh_env)
            finally:
                run_command("rm -fr %s" % tmpdir)

        if 'acl_config' in section:
            tmpdir = tempfile.mkdtemp()
            try:
                repo_path = os.path.join(tmpdir, 'repo')
                ret, _ = run_command_status("git init %s" % repo_path)
                if ret != 0:
                    continue
                if (fetch_config(project, remote_url, repo_path, ssh_env) and
                    copy_acl_config(project, repo_path,
                                    section['acl_config']) and
                    create_groups_file(project, gerrit, repo_path)):
                    push_acl_config(project, remote_url, repo_path, ssh_env)
            finally:
                run_command("rm -fr %s" % tmpdir)
finally:
    os.unlink(ssh_env['GIT_SSH'])
