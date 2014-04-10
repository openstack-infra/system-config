#!/usr/bin/env python

import subprocess
import sys

import yaml

count = 0
projects = []
programs = yaml.load(open('openstack/governance/reference/programs.yaml'))
for program in programs:
    if 'projects' in programs[program]:
        for state in sys.argv[3:]:
            if state in programs[program]['projects']:
                for project in programs[program]['projects'][state]:
                    if project not in projects:
                        projects.append(project)
for project in projects:
    commits = subprocess.Popen(('git', '--git-dir=%s/.git'%project, 'log',
        '--no-merges', '--date=local', '--pretty=format:%h',
        '--after=%s'%sys.argv[1], '--before=%s'%sys.argv[2], 'origin/master'
        ), stdout=subprocess.PIPE).communicate()[0].strip().split('\n')
    count += len(commits)
print(count)
