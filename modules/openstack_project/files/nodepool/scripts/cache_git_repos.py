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

import os.path
import re
import shutil
import urllib2

from common import run_local

URL = ('http://git.openstack.org/cgit/openstack-infra/config/plain/'
       'modules/openstack_project/files/review.projects.yaml')
PROJECT_RE = re.compile('^-?\s+project:\s+(.*)$')


def clone_repo(project):
    remote = 'git://git.openstack.org/%s.git' % project

    # Clear out any existing target directory first, in case of a retry.
    try:
        shutil.rmtree(os.path.join('/opt/git', project))
    except OSError:
        pass

    # Try to clone the requested git repository.
    (status, out) = run_local(['git', 'clone', remote, project],
                              status=True, cwd='/opt/git')

    # If it claims to have worked, make sure we can list branches.
    if status == 0:
        (status, moreout) = run_local(['git', 'branch', '-a'], status=True,
                                      cwd=os.path.join('/opt/git', project))
        out = '\n'.join((out, moreout))

    # If that worked, try resetting to HEAD to make sure it's there.
    if status == 0:
        (status, moreout) = run_local(['git', 'reset', '--hard', 'HEAD'],
                                      status=True,
                                      cwd=os.path.join('/opt/git', project))
        out = '\n'.join((out, moreout))

    # Status of 0 imples all the above worked, 1 means something failed.
    return (status, out)


def main():
    # TODO(jeblair): use gerrit rest api when available
    data = urllib2.urlopen(URL).read()
    for line in data.split('\n'):
        # We're regex-parsing YAML so that we don't have to depend on the
        # YAML module which is not in the stdlib.
        m = PROJECT_RE.match(line)
        if m:
            (status, out) = clone_repo(m.group(1))
            print out
            if status != 0:
                print 'Retrying to clone %s' % m.group(1)
                (status, out) = clone_repo(m.group(1))
                print out
                if status != 0:
                    raise Exception('Failed to clone %s' % m.group(1))


if __name__ == '__main__':
    main()
