#!/usr/bin/env python

import os
import re

from launchpadlib import launchpad
from launchpadlib import uris

import jeepyb.gerritdb
import json
import requests
import yaml

git_url = 'https://git.openstack.org/cgit/'
programs_file = 'openstack/governance/plain/reference/programs.yaml'
projects_file = ('openstack-infra/config/plain/modules/openstack_project/'
                 'files/review.projects.yaml')
acl_directory = ('openstack-infra/config/plain/modules/openstack_project/'
                 'files/gerrit/acls/')
aprv_pattern = 'label-Approved = \+0\.\.\+1 group (.*)'
programs_yaml = yaml.load(requests.get(git_url + programs_file).text)
projects_yaml = yaml.load(requests.get(git_url + projects_file).text)
projects = {}
aprv_groups = {}
for project in projects_yaml:
    projects[project['project']] = {'approvers': {}}
    if 'acl-config' in project:
        acl_file = project['acl-config'].replace('/home/gerrit2/acls/', '')
    else:
        acl_file = project['project'] + '.config'
    acl_ini = requests.get(git_url + acl_directory + acl_file).text
    for aprv_group in [str(x) for x in re.findall(aprv_pattern, acl_ini)]:
        if aprv_group not in projects[project['project']]['approvers']:
            projects[project['project']]['approvers'][aprv_group] = []
        if aprv_group not in aprv_groups:
            aprv_groups[aprv_group] = []
for program in programs_yaml:
    if 'projects' in programs_yaml[program]:
        if 'integrated' in programs_yaml[program]['projects']:
            for project in programs_yaml[program]['projects']['integrated']:
                if project in projects:
                    projects[project]['program'] = program
                    projects[project]['integrated'] = True
        if 'other' in programs_yaml[program]['projects']:
            for project in programs_yaml[program]['projects']['other']:
                if project in projects:
                    projects[project]['program'] = program
cursor = jeepyb.gerritdb.connect().cursor()
group_map = {}
cursor.execute('select group_id,name from account_groups')
for group_id, group_name in cursor.fetchall():
    group_map[group_id] = group_name
group_includes = {}
cursor.execute('select group_id,include_id from account_group_includes')
for group_id, include_id in cursor.fetchall():
    if group_map[group_id] not in group_includes:
        group_includes[group_map[group_id]] = []
    group_includes[group_map[group_id]].append(group_map[include_id])
for project in projects:
    approvers_list = list(projects[project]['approvers'])
    while True:
        new_approvers = approvers_list[:]
        for approver in new_approvers:
            if approver in group_includes:
                for new_approver in group_includes[approver]:
                    if new_approver not in new_approvers:
                        new_approvers.append(new_approver)
                    if new_approver not in aprv_groups:
                        aprv_groups[new_approver] = []
        if new_approvers != approvers_list:
            for approver in new_approvers:
                if approver not in projects[project]['approvers']:
                    projects[project]['approvers'][approver] = []
            approvers_list = new_approvers[:]
        else:
            break
accounts = {}
cursor.execute('select group_id,account_id from account_group_members')
for group_id, account_id in cursor.fetchall():
    if group_map[group_id] in aprv_groups:
        aprv_groups[group_map[group_id]].append(account_id)
        if account_id not in accounts:
            accounts[account_id] = {}
cursor.execute('select account_id,full_name,preferred_email from accounts')
for account_id, full_name, preferred_email in cursor.fetchall():
    if account_id in accounts:
        if full_name:
            full_name = full_name.decode('iso-8859-1').encode('utf-8')
            full_name = full_name.replace('"', "'")
            accounts[account_id]['name'] = full_name
        if preferred_email:
            preferred_email = preferred_email.decode('iso-8859-1')
            preferred_email = preferred_email.encode('utf-8')
            accounts[account_id]['e-mail'] = preferred_email
cursor.execute('select account_id,external_id from account_external_ids '
               'where external_id like "https://login.launchpad.net%%"')
lpconn = launchpad.Launchpad.login_with(
    'Gerrit User Sync', uris.LPNET_SERVICE_ROOT,
    os.path.expanduser('~/.launchpadlib/cache'),
    credentials_file=os.path.expanduser('~/.launchpadlib/creds'),
    version='devel')
for account_id, external_id in cursor.fetchall():
    if account_id in accounts:
        launchpad_id = lpconn.people.getByOpenIDIdentifier(
            identifier=external_id)
        if launchpad_id and 'launchpad' not in accounts[account_id]:
            accounts[account_id]['launchpad'] = str(launchpad_id.name)
for project in projects:
    for aprv_group in projects[project]['approvers'].keys():
        for approver in aprv_groups[aprv_group]:
            if 'name' in accounts[approver]:
                approver_details = '"%s"' % accounts[approver]['name']
            else:
                approver_details = ''
            if 'e-mail' in accounts[approver]:
                if approver_details:
                    approver_details += ' '
                approver_details += '<%s>' % accounts[approver]['e-mail']
            if 'launchpad' in accounts[approver]:
                if approver_details:
                    approver_details += ' '
                approver_details += '(lp:%s)' % accounts[approver]['launchpad']
            projects[project]['approvers'][aprv_group].append(approver_details)
approvers_yaml = open('approvers.yaml', 'w')
yaml.dump(projects, approvers_yaml, allow_unicode=True, encoding='utf-8',
          default_flow_style=False)
approvers_json = open('approvers.json', 'w')
json.dump(projects, approvers_json, indent=2)
