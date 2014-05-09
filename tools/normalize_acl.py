#!/usr/bin/env python

import re
import sys

aclfile = sys.argv[1]
acl = {}
out = ''

aclfd = open(aclfile)
for line in aclfd:
    # condense whitespace to single spaces and get rid of leading/trailing
    line = re.sub('\s+', ' ', line).strip()
    # skip empty lines
    if not line:
        continue
    # this is a section heading
    if line.startswith('['):
        section = line.strip(' []')
        acl[section] = {}
    # key=value lines
    elif '=' in line:
        key, value = line.split('=')
        acl[section][key.strip()] = value.strip()
    # WTF
    else:
        raise Exception('Unrecognized line!')
aclfd.close()

try:
    # create on refs/tags is unnecessary
    del(acl['access "refs/tags/*"']['create'])
except KeyError:
    pass

try:
    # get rid of project.state=active
    if acl['project']['state'] == 'active':
        del(acl['project']['state'])
except KeyError:
    pass

try:
    # get rid of project.status=active
    if acl['project']['status'] == 'active':
        del(acl['project']['status'])
except KeyError:
    pass

for section in acl.keys():
    try:
        # get rid of *.owner=group Administrators
        if acl[section]['owner'] == 'group Administrators':
            del(acl[section]['owner'])
    except KeyError:
        pass
    try:
        # sort exclusiveGroupPermissions
        exclusive = acl[section]['exclusiveGroupPermissions']
        exclusive = ' '.join(sorted(exclusive.split()))
        acl[section]['exclusiveGroupPermissions'] = exclusive
    except KeyError:
        pass

aclfd = open(aclfile, 'w')
for section in sorted(acl.keys()):
    if acl[section]:
        out += '\n[%s]\n' % section
        for key in sorted(acl[section].keys()):
            out += '%s = %s\n' % (key, acl[section][key])
aclfd.write(out[1:])
aclfd.close()
