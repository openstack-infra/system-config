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

# Github pull requests closer reads a project config file called projects.yaml
# It should look like:

# - homepage: http://openstack.org
#   team-id: 153703
#   has-wiki: False
#   has-issues: False
#   has-downloads: False
# ---
# - project: PROJECT_NAME
#   options:
#   - has-pull-requests

# Github authentication information is read from github.secure.config,
# which should look like:

# [github]
# username = GITHUB_USERNAME
# password = GITHUB_PASSWORD
#
# or
#
# [github]
# oauth_token = GITHUB_OAUTH_TOKEN

import ConfigParser
import github
import os
import yaml
import logging

logging.basicConfig(level=logging.ERROR)

PROJECTS_YAML = os.environ.get('PROJECTS_YAML',
                               '/home/gerrit2/projects.yaml')
GITHUB_SECURE_CONFIG = os.environ.get('GITHUB_SECURE_CONFIG',
                                      '/etc/github/github.secure.config')

MESSAGE = """Thank you for contributing to OpenStack!

%(project)s uses Gerrit for code review.

Please visit http://wiki.openstack.org/GerritWorkflow and follow the instructions there to upload your change to Gerrit.
"""

secure_config = ConfigParser.ConfigParser()
secure_config.read(GITHUB_SECURE_CONFIG)
(defaults, config) = [config for config in yaml.load_all(open(PROJECTS_YAML))]

if secure_config.has_option("github", "oauth_token"):
    ghub = github.Github(secure_config.get("github", "oauth_token"))
else:
    ghub = github.Github(secure_config.get("github", "username"),
                         secure_config.get("github", "password"))

orgs = ghub.get_user().get_orgs()
orgs_dict = dict(zip([o.login.lower() for o in orgs], orgs))
for section in config:
    project = section['project']

    # Make sure we're supposed to close pull requests for this project:
    if 'options' in section and 'has-pull-requests' in section['options']:
        continue

    # Find the project's repo
    project_split = project.split('/', 1)
    if len(project_split) > 1:
        repo = orgs_dict[project_split[0].lower()].get_repo(project_split[1])
    else:
        repo = ghub.get_user().get_repo(project)

    # Close each pull request
    pull_requests = repo.get_pulls("open")
    for req in pull_requests:
        vars = dict(project=project)
        issue_data = {"url": repo.url + "/issues/" + str(req.number)}
        issue = github.Issue.Issue(req._requester, issue_data, completed = True)
        issue.create_comment(MESSAGE % vars)
        req.edit(state = "closed")
