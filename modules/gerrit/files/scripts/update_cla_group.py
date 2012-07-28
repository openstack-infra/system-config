#! /usr/bin/env python
# Copyright (C) 2011 OpenStack, LLC.
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

# Add launchpad ids listed in the wiki CLA page to the CLA group in LP.

import os
import urllib
import re

from launchpadlib.launchpad import Launchpad
from launchpadlib.uris import LPNET_SERVICE_ROOT

DEBUG = False

LP_CACHE_DIR = '~/.launchpadlib/cache'
LP_CREDENTIALS = '~/.launchpadlib/creds'
CONTRIBUTOR_RE = re.compile(r'.*?\|\|\s*(?P<name>.*?)\s*\|\|\s*(?P<login>.*?)\s*\|\|\s*(?P<trans>.*?)\s*\|\|.*?')
LINK_RE = re.compile(r'\[\[.*\|\s*(?P<name>.*)\s*\]\]')

for check_path in (os.path.dirname(LP_CACHE_DIR),
                   os.path.dirname(LP_CREDENTIALS)):
    if not os.path.exists(check_path):
        os.makedirs(check_path)

wiki_members = []
for line in urllib.urlopen('http://wiki.openstack.org/Contributors?action=raw'):
    m = CONTRIBUTOR_RE.match(line)
    if m and m.group('login') and m.group('trans'):
        login = m.group('login')
        if login=="<#c0c0c0>'''Launchpad ID'''": continue
        l = LINK_RE.match(login)
        if l:
            login = l.group('name')
        wiki_members.append(login)

launchpad = Launchpad.login_with('CLA Team Sync', LPNET_SERVICE_ROOT,
                                 LP_CACHE_DIR,
                                 credentials_file = LP_CREDENTIALS)

lp_members = []

team = launchpad.people['openstack-cla']
for detail in team.members_details:
    user = None
    # detail.self_link ==
    # 'https://api.launchpad.net/1.0/~team/+member/${username}'
    login = detail.self_link.split('/')[-1]
    status = detail.status
    lp_members.append(login)

for wm in wiki_members:
    if wm not in lp_members:
        print "Need to add %s to LP" % (wm)
        try:
            person = launchpad.people[wm]
        except:
            print 'Unable to find %s on LP'%wm
            continue
        status = team.addMember(person=person, status="Approved")
