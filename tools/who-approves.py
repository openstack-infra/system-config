#!/usr/bin/env python

# Copyright (c) 2015 OpenStack Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Description: When run using OpenStack's Gerrit server, this builds
# JSON and YAML representations of repos with information on the
# official owning project team if any, deliverable tags, and groups
# with approve rights listing the members of each along with their
# Gerrit preferred E-mail addresses and usernames when available.

# Rationale: It was done as a demonstration to a representative of a
# foundation member company who requested a list of the "core
# reviewers" for official projects, optionally broken down by
# integrated vs. other. I'm attempting to show that this data is
# already publicly available and can be extracted/analyzed by anyone
# without needing to request it.

# Use: This needs your Gerrit username passed as the command-line
# parameter, found at https://review.openstack.org/#/settings/ when
# authenticated in the WebUI. It also prompts for an HTTP password
# which https://review.openstack.org/#/settings/http-password will
# allow you to generate. The results end up in files named
# approvers.json and approvers.yaml. At the time of writing, it
# takes approximately 6.5 minutes to run on a well-connected machine
# with 70-80ms round-trip latency to review.openstack.org.

# Example:
#
#     $ virtualenv approvers
#     [...]
#     $ ./approvers/bin/pip install pyyaml requests
#     [...]
#     $ ./approvers/bin/python tools/who-approves.py fungi
#     Password:
#     [wait for completion]
#     $ ./approvers/bin/python
#     >>> import yaml
#     >>>
#     >>> def get_approvers(repos):
#     ...     approvers = set()
#     ...     for repo in repos:
#     ...         for group in repos[repo]['approvers']:
#     ...             for approver in repos[repo]['approvers'][group]:
#     ...                 approvers.add(approver)
#     ...     return(approvers)
#     ...
#     >>> p = yaml.load(open('approvers.yaml'))
#     >>> print('Total repos: %s' % len(p))
#     Total repos: 751
#     >>> print('Total approvers: %s' % len(get_approvers(p)))
#     Total approvers: 849
#     >>>
#     >>> o = {k: v for k, v in p.iteritems() if 'team' in v}
#     >>> print('Repos for official teams: %s' % len(o))
#     Repos for official teams: 380
#     >>> print('OpenStack repo approvers: %s' % len(get_approvers(o)))
#     OpenStack repo approvers: 456
#     >>>
#     >>> i = {k: v for k, v in p.iteritems() if 'tags' in v
#     ...      and 'release:managed' in v['tags']}
#     >>> print('Repos under release management: %s' % len(i))
#     Repos under release management: 77
#     >>> print('Managed release repo approvers: %s' % len(get_approvers(i)))
#     Managed release repo approvers: 245

import getpass
import json
import re
import sys

import requests
import yaml

gerrit_url = 'https://review.openstack.org/'
try:
    gerrit_auth = requests.auth.HTTPDigestAuth(sys.argv[1], getpass.getpass())
except IndexError:
    sys.stderr.write("Usage: %s USERNAME\n" % sys.argv[0])
    sys.exit(1)
acl_path = 'gitweb?p=%s.git;a=blob_plain;f=project.config;hb=refs/meta/config'
group_path = 'a/groups/%s/members/?recursive&pp=0'
projects_file = ('gitweb?p=openstack/governance.git;a=blob_plain;'
                 'f=reference/projects.yaml;hb=%s')
ref_name = 'refs/heads/master'
aprv_pattern = 'label-Workflow = .*\.\.\+1 group (.*)'
projects = yaml.safe_load(
    requests.get(gerrit_url + projects_file % ref_name).text)
repos_dump = json.loads(requests.get(
    gerrit_url + 'projects/?pp=0').text[4:])
all_groups = json.loads(requests.get(gerrit_url + 'a/groups/',
                                     auth=gerrit_auth).text[4:])
repos = {}
aprv_groups = {}
for repo in repos_dump:
    repos[repo.encode('utf-8')] = {'approvers': {}}
    acl_ini = requests.get(gerrit_url + acl_path % repo).text
    for aprv_group in [str(x) for x in re.findall(aprv_pattern, acl_ini)]:
        if aprv_group not in repos[repo]['approvers']:
            repos[repo]['approvers'][aprv_group] = []
        if aprv_group not in aprv_groups:
            aprv_groups[aprv_group] = []
for team in projects:
    if 'deliverables' in projects[team]:
        for deli in projects[team]['deliverables']:
            if 'repos' in projects[team]['deliverables'][deli]:
                drepos = projects[team]['deliverables'][deli]['repos']
                for repo in drepos:
                    if repo in repos:
                        repos[repo]['team'] = team
                        if 'tags' in projects[team]['deliverables'][deli]:
                            repos[repo]['tags'] = \
                                projects[team]['deliverables'][deli]['tags']
for aprv_group in aprv_groups.keys():
    # It's possible for built-in metagroups in recent Gerrit releases to
    # appear in ACLs but not in the groups list
    if aprv_group in all_groups:
        aprv_groups[aprv_group] = json.loads(requests.get(
            gerrit_url + group_path % all_groups[aprv_group]['id'],
            auth=gerrit_auth).text[4:])
    else:
        sys.stderr.write('Ignoring nonexistent "%s" group.\n' % aprv_group)
for repo in repos:
    for aprv_group in repos[repo]['approvers'].keys():
        for approver in aprv_groups[aprv_group]:
            if 'name' in approver:
                approver_details = '"%s"' % approver['name']
            else:
                approver_details = ''
            if 'email' in approver:
                if approver_details:
                    approver_details += ' '
                approver_details += '<%s>' % approver['email']
            if 'username' in approver:
                if approver_details:
                    approver_details += ' '
                approver_details += '(%s)' % approver['username']
            repos[repo]['approvers'][aprv_group].append(
                approver_details.encode('utf-8'))
approvers_yaml = open('approvers.yaml', 'w')
yaml.dump(repos, approvers_yaml, allow_unicode=True, encoding='utf-8',
          default_flow_style=False)
approvers_json = open('approvers.json', 'w')
json.dump(repos, approvers_json, indent=2)
