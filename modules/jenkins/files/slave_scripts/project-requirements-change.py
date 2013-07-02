#! /usr/bin/env python
# Copyright (C) 2011 OpenStack, LLC.
# Copyright (c) 2013 Hewlett-Packard Development Company, L.P.
# Copyright (c) 2013 OpenStack Foundation
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

import os
import pkg_resources
import shlex
import shutil
import subprocess
import sys
import tempfile

def run_command(cmd):
    print(cmd)
    cmd_list = shlex.split(str(cmd))
    p = subprocess.Popen(cmd_list, stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT)
    (out, nothing) = p.communicate()
    return out.strip()

class RequirementsList(object):
    def __init__(self, name):
        self.name = name
        self.reqs = {}
        self.failed = False

    def read_requirements(self, fn):
        for line in open(fn):
            line = line[:line.find('#')]
            line = line.strip()
            if (not line or
                line.startswith('http') or
                line.startswith('-e') or
                line.startswith('-f')):
                continue
            req = pkg_resources.Requirement.parse(line)
            if req.project_name.lower() in self.reqs:
                print("Duplicate requirement in %s: %s" %
                      (self.name, str(req)))
                self.failed = True
            self.reqs[req.project_name.lower()] = req

    def read_all_requirements(self):
        for fn in ['tools/pip-requires',
                   'tools/test-requires',
                   'requirements.txt',
                   'test-requirements.txt',
                   ]:
            if os.path.exists(fn):
                self.read_requirements(fn)


def main():
    branch = sys.argv[1]
    head = run_command("git rev-parse HEAD").strip()
    head_reqs = RequirementsList('HEAD')
    head_reqs.read_all_requirements()

    run_command("git remote update")
    run_command("git checkout remotes/origin/%s" % branch)
    branch_reqs = RequirementsList(branch)
    branch_reqs.read_all_requirements()

    run_command("git checkout %s" % head)

    reqroot = tempfile.mkdtemp()
    reqdir = os.path.join(reqroot, "requirements")
    run_command("git clone https://review.openstack.org/p/openstack/"
                "requirements --depth 1 %s" % reqdir)
    os.chdir(reqdir)
    run_command("git checkout remotes/origin/%s" % branch)
    print "requirements git sha: %s" % run_command(
        "git rev-parse HEAD").strip()
    os_reqs = RequirementsList('openstack/requirements')
    os_reqs.read_all_requirements()

    failed = False
    for req in head_reqs.reqs.values():
        name = req.project_name.lower()
        if name in branch_reqs.reqs and req == branch_reqs.reqs[name]:
            continue
        if name not in os_reqs.reqs:
            print("Requirement %s not in openstack/requirements" % str(req))
            failed = True
            continue
        # pkg_resources.Requirement implements __eq__() but not __ne__().
        # There is no implied relationship between __eq__() and __ne__()
        # so we must negate the result of == here instead of using !=.
        if not (req == os_reqs.reqs[name]):
            print("Requirement %s does not match openstack/requirements "
                  "value %s" % (str(req), str(os_reqs.reqs[name])))
            failed = True

    shutil.rmtree(reqroot)
    if failed or os_reqs.failed or head_reqs.failed or branch_reqs.failed:
        sys.exit(1)
    print("Updated requirements match openstack/requirements.")


if __name__ == '__main__':
    main()
