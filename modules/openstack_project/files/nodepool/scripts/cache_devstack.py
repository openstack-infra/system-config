#!/usr/bin/env python

# Copyright (C) 2011-2013 OpenStack Foundation
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
#
# See the License for the specific language governing permissions and
# limitations under the License.

import os
import sys

from common import run_local

DEVSTACK = os.path.expanduser('~/workspace-cache/devstack')
CACHEDIR = os.path.expanduser('~/cache/files')


def git_branches():
    branches = []
    for branch in run_local(['git', 'branch', '-a'], cwd=DEVSTACK).split("\n"):
        branch = branch.strip()
        if not branch.startswith('remotes/origin'):
            continue
        branches.append(branch)
    return branches


def tokenize(fn, tokens, distribution, comment=None):
    for line in open(fn):
        if 'dist:' in line and ('dist:%s' % distribution not in line):
            continue
        if 'qpid' in line:
            continue  # TODO: explain why this is here
        if comment and comment in line:
            line = line[:line.rfind(comment)]
        line = line.strip()
        if line and line not in tokens:
            tokens.append(line)


def local_prep(distribution):
    branches = []
    for branch in git_branches():
        # Ignore branches of the form 'somestring -> someotherstring'
        # as this denotes a symbolic reference and the entire string
        # as is cannot be checked out. We can do this safely as the
        # reference will refer to one of the other branches returned
        # by git_branches.
        if ' -> ' in branch:
            continue
        branch_data = {'name': branch}
        print 'Branch: ', branch
        run_local(['git', 'checkout', branch], cwd=DEVSTACK)
        run_local(['git', 'pull', '--ff-only', 'origin'], cwd=DEVSTACK)

        if os.path.exists('/usr/bin/apt-get'):
            debs = []
            debdir = os.path.join(DEVSTACK, 'files', 'apts')
            for fn in os.listdir(debdir):
                fn = os.path.join(debdir, fn)
                tokenize(fn, debs, distribution, comment='#')
            branch_data['debs'] = debs

        if os.path.exists('/usr/bin/rpm'):
            rpms = []
            rpmdir = os.path.join(DEVSTACK, 'files', 'rpms')
            for fn in os.listdir(rpmdir):
                fn = os.path.join(rpmdir, fn)
                tokenize(fn, rpms, distribution, comment='#')
            branch_data['rpms'] = rpms

        images = []
        for line in open(os.path.join(DEVSTACK, 'stackrc')):
            line = line.strip()
            if line.startswith('IMAGE_URLS'):
                if '#' in line:
                    line = line[:line.rfind('#')]
                if line.endswith(';;'):
                    line = line[:-2]
                line = line.split('=', 1)[1].strip()
                if line.startswith('${IMAGE_URLS:-'):
                    line = line[len('${IMAGE_URLS:-'):]
                if line.endswith('}'):
                    line = line[:-1]
                if line[0] == line[-1] == '"':
                    line = line[1:-1]
                images += [x.strip() for x in line.split(',')]
        branch_data['images'] = images
        branches.append(branch_data)
    return branches


def main():
    distribution = sys.argv[1]

    branches = local_prep(distribution)
    image_filenames = {}
    for branch_data in branches:
        if branch_data.get('debs'):
            run_local(['sudo', 'apt-get', '-y', '-d', 'install'] +
                      branch_data['debs'])
        elif branch_data.get('rpms'):
            run_local(['sudo', 'yum', 'install', '-y', '--downloadonly'] +
                      branch_data['rpms'])
        else:
            sys.exit('No supported package data found.')

        for url in branch_data['images']:
            fname = url.split('/')[-1]
            if fname in image_filenames:
                continue
            run_local(['wget', '-nv', '-c', url,
                       '-O', os.path.join(CACHEDIR, fname)])

if __name__ == '__main__':
    main()
