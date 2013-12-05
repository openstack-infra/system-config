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

import re
import urllib2

from common import run_local

URL = ('http://git.openstack.org/cgit/openstack-infra/config/plain/'
       'modules/openstack_project/templates/review.projects.yaml.erb')
PROJECT_RE = re.compile('^-?\s+project:\s+(.*)$')


def main():
    # TODO(jeblair): use gerrit rest api when available
    data = urllib2.urlopen(URL).read()
    for line in data.split('\n'):
        # We're regex-parsing YAML so that we don't have to depend on the
        # YAML module which is not in the stdlib.
        m = PROJECT_RE.match(line)
        if m:
            project = 'https://git.openstack.org/%s' % m.group(1)
            print run_local(['git', 'clone', project, m.group(1)],
                            cwd='/opt/git')


if __name__ == '__main__':
    main()
