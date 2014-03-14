#!/usr/bin/env python

import json
import os
import re

import requests
import yaml

gerrit_url = 'https://review.openstack.org/'
gerrit_auth = requests.auth.HTTPDigestAuth('GERRITUSER','HTTPPASSWORD')
acl_path = 'gitweb?p=%s.git;a=blob_plain;f=project.config;hb=refs/meta/config'
group_path = 'a/groups/%s/members/?recursive&pp=0'
programs_file = ('gitweb?p=openstack/governance.git;a=blob_plain;'
                 'f=reference/programs.yaml;hb=%s')
ref_name = 'refs/heads/master'
aprv_pattern = 'label-Workflow = .*\.\.\+1 group (.*)'
programs = yaml.load(requests.get(gerrit_url+programs_file%ref_name).text)
projects_dump = json.loads(requests.get(gerrit_url+'projects/?pp=0').text[4:])
all_groups = json.loads(requests.get(gerrit_url+'a/groups/',
                                     auth=gerrit_auth).text[4:])
projects = {}
aprv_groups = {}
for project in projects_dump:
    projects[project.encode('utf-8')] = {'approvers': {}}
    acl_ini = requests.get(gerrit_url+acl_path%project).text
    for aprv_group in [str(x) for x in re.findall(aprv_pattern, acl_ini)]:
        if aprv_group not in projects[project]['approvers']:
            projects[project]['approvers'][aprv_group] = []
        if aprv_group not in aprv_groups:
            aprv_groups[aprv_group] = []
for program in programs:
    if 'projects' in programs[program]:
        for project in programs[program]['projects']:
            if project['repo'] in projects:
                projects[project['repo']]['program'] = program
                if 'integrated-since' in project:
                    projects[project['repo']]['integrated'] = True
for aprv_group in aprv_groups.keys():
    aprv_groups[aprv_group] = json.loads(requests.get(
            gerrit_url+group_path%all_groups[aprv_group]['id'],
            auth=gerrit_auth).text[4:])
for project in projects:
    for aprv_group in projects[project]['approvers'].keys():
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
            projects[project]['approvers'][aprv_group].append(approver_details.encode('utf-8'))
approvers_yaml = open('approvers.yaml', 'w')
yaml.dump(projects, approvers_yaml, allow_unicode=True, encoding='utf-8',
          default_flow_style=False)
approvers_json = open('approvers.json', 'w')
json.dump(projects, approvers_json, indent=2)
