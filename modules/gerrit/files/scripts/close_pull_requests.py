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

# Close Github pull requests with instructions to use Gerrit for
# code review.  The list of projects is found in github.config
# and should look like:

# [project "GITHUB_PROJECT"]
# close_pull = true

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

import github
import os
import ConfigParser
import logging
import re

logging.basicConfig(level=logging.ERROR)

GITHUB_CONFIG = os.environ.get('GITHUB_CONFIG',
                               '/home/gerrit2/github.config')
GITHUB_SECURE_CONFIG = os.environ.get('GITHUB_SECURE_CONFIG',
                                      '/home/gerrit2/github.secure.config')

MESSAGE = """Thank you for contributing to OpenStack!

%(project)s uses Gerrit for code review.

Please visit http://wiki.openstack.org/GerritWorkflow and follow the instructions there to upload your change to Gerrit.
"""

PROJECT_RE = re.compile(r'^project\s+"(.*)"$')

secure_config = ConfigParser.ConfigParser()
secure_config.read(GITHUB_SECURE_CONFIG)
config = ConfigParser.ConfigParser()
config.read(GITHUB_CONFIG)

if secure_config.has_option("github", "oauth_token"):
    ghub = github.Github(secure_config.get("github", "oauth_token"))
else:
    ghub = github.Github(secure_config.get("github", "username"),
                         secure_config.get("github", "password"))

for section in config.sections():
    # Each section looks like [project "openstack/project"]
    m = PROJECT_RE.match(section)
    if not m: continue
    project = m.group(1)

    # Make sure we're supposed to close pull requests for this project:
    if not (config.has_option(section, "close_pull") and
            config.get(section, "close_pull").lower() == 'true'):
        continue

    # Close each pull request
    repo = ghub.get_user().get_repo(project)
    pull_requests = repo.get_pulls("open")
    for req in pull_requests:
        vars = dict(project=project)
        issue = repo.get_issue(req.number)
        issue.create_comment(MESSAGE % vars)
        req.edit(state = "closed")
