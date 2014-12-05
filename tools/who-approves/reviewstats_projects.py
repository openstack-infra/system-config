#!/usr/bin/env python

# 2 Issues here:
# 1) The core teams have also got the stable approvers.
# I think this is due to the way that the approvers are picked out from the
# project acl file (it's like an ini file). The users need to be only from the
# [access "refs/heads/*"] and not the [access "refs/heads/proposed/*"] and this
# requires essentially parsing the file, which isn't done currently.
#
# 2) All projects in a program are lumped together.
# For example, the Keystone program has a couple of distinct core groups,
# there's the core group for keystone, python-keystoneclient, and there's a
# different core group for pycadf.
# This info isn't in programs.yaml.
# Maybe this can be fixed by having a reviewstats config file that has a
# mapping of program -> mapping of special_group -> list of projects
# if the project doesn't have a special group then it's just in the program.

import json
import os
import re

import requests
import yaml


gerrit_url = 'https://review.openstack.org/'
gerrit_auth = requests.auth.HTTPDigestAuth('GERRITUSER', 'HTTPPASSWORD')
acl_path = 'gitweb?p=%s.git;a=blob_plain;f=project.config;hb=refs/meta/config'
group_path = 'a/groups/%s/members/?recursive&pp=0'
programs_file = ('gitweb?p=openstack/governance.git;a=blob_plain;'
                 'f=reference/programs.yaml;hb=%s')
ref_name = 'refs/heads/master'
aprv_pattern = 'label-Workflow = .*\.\.\+1 group +(.*)'

programs = yaml.load(requests.get(gerrit_url + programs_file % ref_name).text)
with open('programs.yaml', 'w') as programs_cache:
    yaml.dump(programs, programs_cache, allow_unicode=True, encoding='utf-8',
          default_flow_style=False)
print 'Wrote programs.yaml'

projects_dump = json.loads(requests.get(gerrit_url + 'projects/?pp=0').text[4:])
with open('projects.json', 'w') as projects_cache:
    json.dump(projects_dump, projects_cache, indent=2)
print 'Wrote projects.json'

all_groups = json.loads(requests.get(gerrit_url + 'a/groups/',
                                     auth=gerrit_auth).text[4:])
with open('all_groups.json', 'w') as all_groups_cache:
    json.dump(all_groups, all_groups_cache, indent=2)
print 'Wrote all_groups.json'

projects = {}
aprv_groups = {}

try:
    os.mkdir('project_cache')
except OSError:
    pass

for project in projects_dump:
    projects[project.encode('utf-8')] = {'approvers': {}}
    try:
        with open('project_cache/%s' % project.replace('/', '_'), 'r') as proj_cache:
            acl_ini = proj_cache.read()
    except Exception:
        acl_ini = requests.get(gerrit_url + acl_path % project).text
        print 'GET %s ->\n%s' % (gerrit_url + acl_path % project, acl_ini)
        with open('project_cache/%s' % project.replace('/', '_'), 'w') as proj_cache:
            proj_cache.write(acl_ini)
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

try:
    os.mkdir('group_cache')
except OSError:
    pass

for aprv_group in aprv_groups.keys():
    try:
        with open('group_cache/%s' % aprv_group, 'r') as group_cache:
            aprv_groups[aprv_group] = json.load(group_cache)
    except Exception:
        aprv_groups[aprv_group] = json.loads(requests.get(
                gerrit_url + group_path % all_groups[aprv_group]['id'],
                auth=gerrit_auth).text[4:])
        print 'GET %s ->\n%s' % (
            gerrit_url + group_path % all_groups[aprv_group]['id'],
            aprv_groups[aprv_group])
        with open('group_cache/%s' % aprv_group, 'w') as group_cache:
            json.dump(aprv_groups[aprv_group], group_cache, indent=2)

try:
    os.mkdir('projects')
except OSError:
    pass

for program_name in programs:

    program = programs[program_name]
    codename = program.get('codename', program_name)

    subprojects = set()
    for project_data in program['projects']:
        if 'repo' not in project_data:
            continue
        subprojects.add(project_data['repo'])

    groups = set()
    for subproject in subprojects:
        try:
            groups |= set(projects[subproject]['approvers'].keys())
        except KeyError:
            print 'KeyError for subproject %s in %s' % (subproject, program_name)

    users = set()
    for group in groups:
        for member in aprv_groups[group]:
            users.add(member['username'])

    reviewstats_project = {
        'name': codename,
        'subprojects': sorted(subprojects),
        'core-team': sorted(users),
    }

    with open('projects/%s.json' % codename, 'w') as reviewstats_project_file:
        json.dump(reviewstats_project, reviewstats_project_file, indent=4,
                  sort_keys=True)
