#! /usr/bin/env python

import functools
import logging
import json
import requests
import sys
import yaml

logging.basicConfig(level=logging.ERROR)
#logging.basicConfig(level=logging.DEBUG)

url = 'https://review.openstack.org/projects/'

retired_url = 'https://git.openstack.org/cgit/openstack-infra/project-config/plain/gerrit/projects.yaml'

# This is what a project looks like
'''
  "openstack-attic/akanda": {
    "id": "openstack-attic%2Fakanda",
    "state": "READ_ONLY"
  },
'''

def is_in_openstack_namespace(proj):
    # only interested in openstack namespace (e.g. not retired
    # stackforge, etc)
    return proj.startswith('openstack')

# Check if this project has a plugin file
def has_devstack_plugin(session, proj):
    # Don't link in the deb packaging repos
    if "openstack/deb-" in proj:
        return False
    r = session.get("https://git.openstack.org/cgit/%s/plain/devstack/plugin.sh" % proj)
    return r.status_code == 200

logging.debug("Building retired list")
r = requests.get(retired_url)
projects = yaml.load(r.text)
retired = []
for project in projects:
    if 'acl-config' in project and project['acl-config'].endswith('retired.config'):
        retired.append(project['project'])

logging.debug("Getting project list from %s" % url)
r = requests.get(url)
with requests.Session() as session:
    has_devstack_plugin = functools.partial(has_devstack_plugin, session)
    projects = sorted(filter(is_in_openstack_namespace, json.loads(r.text[4:])))
    logging.debug("Found %d projects" % len(projects))

    if len(sys.argv) == 2 and sys.argv[1] == "devstack":
        projects = filter(has_devstack_plugin, projects)

    projects = sorted(filter(lambda x: x not in retired, projects))
    logging.debug("Filtered to %d projects" % len(projects))
    
    for project in projects:
        print('https://git.openstack.org/'+project)
