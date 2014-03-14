#!/usr/bin/env python

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
    print("Usage: %s USERNAME" % sys.argv[0])
    sys.exit(0)
acl_path = 'gitweb?p=%s.git;a=blob_plain;f=project.config;hb=refs/meta/config'
group_path = 'a/groups/%s/members/?recursive&pp=0'
projects_file = ('gitweb?p=openstack/governance.git;a=blob_plain;'
                 'f=reference/projects.yaml;hb=%s')
ref_name = 'refs/heads/master'
aprv_pattern = 'label-Workflow = .*\.\.\+1 group (.*)'
projects = yaml.load(requests.get(gerrit_url + projects_file % ref_name).text)
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
for project in projects:
    if 'projects' in projects[project]:
        for repo in projects[project]['projects']:
            if repo['repo'] in repos:
                repos[repo['repo']]['project'] = project
                if 'tags' in repo:
                    for tag in repo['tags']:
                        if tag['name'] == 'integrated-release':
                            repos[repo['repo']]['integrated'] = True
for aprv_group in aprv_groups.keys():
    aprv_groups[aprv_group] = json.loads(requests.get(
        gerrit_url + group_path % all_groups[aprv_group]['id'],
        auth=gerrit_auth).text[4:])
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
