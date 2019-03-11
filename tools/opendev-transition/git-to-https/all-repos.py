#! /usr/bin/env python

import functools
import logging
import json
import requests
import sys

logging.basicConfig(level=logging.ERROR)#logging.DEBUG)

url = 'https://review.openstack.org/projects/'

# This is what a project looks like
'''
  "openstack-attic/akanda": {
    "id": "openstack-attic%2Fakanda",
    "state": "READ_ONLY"
  },
'''

# Check if this project has a plugin file
def has_devstack_plugin(proj):
    # Don't link in the deb packaging repos
    if "openstack/deb-" in proj:
        return False
    r = requests.get("https://git.openstack.org/cgit/%s/plain/devstack/plugin.sh" % proj)
    return r.status_code == 200

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


logging.debug("Getting project list from %s" % url)
r = requests.get(url)
with requests.Session() as session:
    has_devstack_plugin = functools.partial(has_devstack_plugin, session)
    projects = sorted(filter(is_in_openstack_namespace, json.loads(r.text[4:])))
    logging.debug("Found %d projects" % len(projects))

    if len(sys.argv) == 2 and sys.argv[1] == "devstack":
        projects = filter(has_devstack_plugin, projects)

    for project in projects:
        print('https://git.openstack.org/'+project)
