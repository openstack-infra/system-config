#!/usr/bin/env python

# Usage: normalize_acl.py acl.config [transformation [transformation [...]]]
#
# Transformations:
# 0 - dry run (default, print to stdout rather than modifying file in place)
# 1 - strip/condense whitespace and sort (implied by any other transformation)
# 2 - get rid of unneeded create on refs/tags
# 3 - remove any project.stat{e,us} = active since it's a default or a typo
# 4 - strip default *.owner = group Administrators permissions
# 5 - sort the exclusiveGroupPermissions group lists

import re
import sys

aclfile = sys.argv[1]

try:
    transformations = sys.argv[2:]
except KeyError:
    transformations = []

acl = {}
out = ''

if '0' in transformations or not transformations:
    dry_run = True
else:
    dry_run = False

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

if '2' in transformations:
    try:
        del(acl['access "refs/tags/*"']['create'])
    except KeyError:
        pass

if '3' in transformations:
    try:
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

    if '4' in transformations:
        try:
            if acl[section]['owner'] == 'group Administrators':
                del(acl[section]['owner'])
        except KeyError:
            pass

    if '5' in transformations:
        try:
            exclusive = acl[section]['exclusiveGroupPermissions']
            exclusive = ' '.join(sorted(exclusive.split()))
            acl[section]['exclusiveGroupPermissions'] = exclusive
        except KeyError:
            pass

for section in sorted(acl.keys()):
    if acl[section]:
        out += '\n[%s]\n' % section
        for key in sorted(acl[section].keys()):
            out += '%s = %s\n' % (key, acl[section][key])

if dry_run:
    print(out[1:-1])
else:
    aclfd = open(aclfile, 'w')
    aclfd.write(out[1:])
    aclfd.close()
