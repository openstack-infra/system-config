#!/usr/bin/python

# Copyright (c) 2018 OpenStack Foundation
#
# This module is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this software.  If not, see <http://www.gnu.org/licenses/>.

DOCUMENTATION = '''
---
module: construct_user_list
short_description: Generate a user dict for ssh key management.
description:
  - Process ssh key information (including combining remote keys)
    for use in user management tasks (particularly authorized_keys).
options:
  valid_users:
    description:
      - A list of usernames that are valid.
    required: true
  all_users:
    description:
      - A dictionary of all possible user configurations.
    required: true
requirements: [ ]
author: Clark Boylan
'''


try:
    import urllib.request as urllib
except ImportError:
    import urllib2 as urllib

# import module snippets
from ansible.module_utils.basic import *


def main():
    module = AnsibleModule(
        argument_spec=dict(
            # See AnsibleModule._CHECK_ARGUMENT_TYPES_DISPATCHER for the
            # names of valid types
            valid_users=dict(required=True, type='list'),
            all_users=dict(required=True, type='dict'),
        ),
    )
    p = module.params

    users = []
    for username, details in p['all_users'].items():
        if username in p['valid_users']:
            user = {}
            user['username'] = username
            if 'key_urls' in details:
                keys = []
                try:
                    for url in details['key_urls']:
                        req = urllib.urlopen(url)
                        keys.append(req.read())
                    user['key'] = b'\n'.join(keys)
                except:
                    # Don't manage user keys if we can't retrieve them
                    # TODO figure out logging?
                    continue
            else:
                user['key'] = details['key']

            users.append(user)
    module.exit_json(users=users)

if __name__ == '__main__':
    main()
