#!/usr/bin/python

# Copyright (c) 2015 Hewlett-Packard Development Company, L.P.
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

from __future__ import print_function

import json
import os
import requests
import sys
from urlparse import urljoin

auth_user = os.environ.get('ZANATA_USER', None)
auth_key = os.environ.get('ZANATA_KEY', None)

if not len(sys.argv) == 2:
    print("This script requires a filename to read the list of projects from.")
    sys.exit(1)

if not auth_user or not auth_key:
    print("This script requires both the ZANATA_USER and ZANATA_KEY "
          "environment variables set.")
    sys.exit(1)

headers = {'Accept': 'application/json', 'Content-Type': 'application/json',
           'X-Auth-User': auth_user, 'X-Auth-Token': auth_key}

project_template = {u'defaultType': u'Gettext', u'status': u'ACTIVE'}
iteration = {u'status': u'ACTIVE', u'projectType': u'Gettext',
                      u'id': u'master'}

projects = set()
with open(sys.argv[1], 'r') as f:
    for line in f:
        if not line or line.startswith('#'):
            continue
        projects.add(line.strip())

if not projects:
    print("No projects parsed from %s." % sys.argv[1])
    sys.exit(1)


def _construct_url(url_fragment):
    return urljoin('https://translate-dev.openstack.org:443/', url_fragment)


def _query_zanata_rest_api(url_fragment):
    request_url = _construct_url(url_fragment)
    return requests.get(request_url, verify=False, headers=headers)


def is_project_registered(project):
    r = _query_zanata_rest_api('/rest/projects/p/%s' % project)
    return r.status_code == 200


def has_master(project):
    r = _query_zanata_rest_api(
        '/rest/projects/p/%s/iterations/i/master' % project)
    return r.status_code == 200


def _put_zanata_rest_api(url_fragment, data):
    request_url = _construct_url(url_fragment)
    r = requests.put(request_url, verify=False, headers=headers,
                     data=json.dumps(data))
    return r.status_code in (200, 201)


def register_project(project):
    project_data = project_template
    project_data[u'id'] = project
    project_data[u'name'] = project
    project_data[u'description'] = project.title()
    return _put_zanata_rest_api('/rest/projects/p/%s' % project, project_data)


def register_master_iteration(project):
    return _put_zanata_rest_api(
        '/rest/projects/p/%s/iterations/i/master' % project, iteration)


for project in sorted(projects):
    registered = is_project_registered(project)
    master = False
    if registered:
        master = has_master(project)
    if registered and master:
        print("Project %s is fully configured." % project)
        continue
    newly_registered = False
    if not registered:
        print("Project %s is not registered." % project)
        newly_registered = True
        if register_project(project):
            print("\tProject registered.")
        else:
            print("\tFailure registering project.")
            continue
    if not master:
        if not newly_registered:
            print("Project %s is registered, without master iteration." %
                  project)
        if register_master_iteration(project):
            print("\tMaster iteration registered.")
        else:
            print("\tFailure registering master iteration.")
